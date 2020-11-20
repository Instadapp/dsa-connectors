pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// import files from common directory
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";
import { TokenInterface } from "../common/interfaces.sol";

interface IGauge {
  function claim_rewards() external;
  function deposit(uint256 value) external;
  function withdraw(uint256 value) external;
  function lp_token() external view returns(address token);
  function rewarded_token() external view returns(address token);
  function crv_token() external view returns(address token);
  function balanceOf(address user) external view returns(uint256 amt);
}

interface IMintor{
  function mint(address gauge) external;
}

interface ICurveGaugeMapping {

  struct GaugeData {
    address gaugeAddress;
    bool rewardToken;
  }

  function gaugeMapping(bytes32) external view returns(GaugeData memory);
}

contract GaugeHelper is DSMath, Stores{
  function getCurveGaugeMappingAddr() internal virtual view returns (address){
    return 0x1C800eF1bBfE3b458969226A96c56B92a069Cc92;
  }

  function getCurveMintorAddr() internal virtual view returns (address){
    return 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
  }

  /**
   * @dev Convert String to bytes32.
   */
  function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
    require(bytes(str).length != 0, "string-empty");
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      result := mload(add(str, 32))
    }
  }
}

contract CurveGaugeEvent is GaugeHelper {
  event LogDeposit(
    string indexed gaugePoolName,
    uint amount,
    uint getId,
    uint setId
  );

  event LogWithdraw(
    string indexed gaugePoolName,
    uint amount,
    uint getId,
    uint setId
  );

  event LogClaimedReward(
    string indexed gaugePoolName,
    uint amount,
    uint rewardAmt,
    uint setId,
    uint setIdReward
  );

  function emitLogWithdraw(string memory gaugePoolName, uint _amt, uint getId, uint setId) internal {
    emit LogWithdraw(gaugePoolName, _amt, getId, setId);
    bytes32 _eventCodeWithdraw = keccak256("LogWithdraw(string,uint256,uint256,uint256)");
    bytes memory _eventParamWithdraw = abi.encode(gaugePoolName, _amt, getId, setId);
    emitEvent(_eventCodeWithdraw, _eventParamWithdraw);
  }

  function emitLogClaimedReward(string memory gaugePoolName, uint crvAmt, uint rewardAmt, uint setIdCrv, uint setIdReward) internal {
    emit LogClaimedReward(gaugePoolName, crvAmt, rewardAmt, setIdCrv, setIdReward);
    bytes32 _eventCode = keccak256("LogClaimedReward(string,uint256,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(gaugePoolName, crvAmt, rewardAmt, setIdCrv, setIdReward);
    emitEvent(_eventCode, _eventParam);
  }
}

contract CurveGauge is CurveGaugeEvent {
  struct Balances{
    uint intialCRVBal;
    uint intialRewardBal;
    uint finalCRVBal;
    uint finalRewardBal;
    uint crvRewardAmt;
    uint rewardAmt;
  }

  /**
  * @dev Deposit Cruve LP Token.
    * @param gaugePoolName Curve gauge pool name.
    * @param amt deposit amount.
    * @param getId Get token amount at this ID from `InstaMemory` Contract.
    * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function deposit(
    string calldata gaugePoolName,
    uint amt,
    uint getId,
    uint setId
  ) external payable {
    uint _amt = getUint(getId, amt);
    ICurveGaugeMapping curveGaugeMapping = ICurveGaugeMapping(getCurveGaugeMappingAddr());
    ICurveGaugeMapping.GaugeData memory curveGaugeData = curveGaugeMapping.gaugeMapping(
        bytes32(stringToBytes32(gaugePoolName)
    ));
    require(curveGaugeData.gaugeAddress != address(0), "wrong-gauge-pool-name");
    IGauge gauge = IGauge(curveGaugeData.gaugeAddress);
    TokenInterface lp_token = TokenInterface(address(gauge.lp_token()));

    _amt = _amt == uint(-1) ? lp_token.balanceOf(address(this)) : _amt;
    lp_token.approve(address(curveGaugeData.gaugeAddress), _amt);

    gauge.deposit(_amt);

    setUint(setId, _amt);

    emit LogDeposit(gaugePoolName, _amt, getId, setId);
    bytes32 _eventCode = keccak256("LogDeposit(string,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(gaugePoolName, _amt, getId, setId);
    emitEvent(_eventCode, _eventParam);
  }

  /**
  * @dev Withdraw LP Token and claim both CRV and Reward token.
    * @param gaugePoolName gauge pool name.
    * @param amt LP token amount.
    * @param getId Get LP token amount at this ID from `InstaMemory` Contract.
    * @param setId Set LP token amount at this ID in `InstaMemory` Contract.
    * @param setIdCrv Set CRV token reward amount at this ID in `InstaMemory` Contract.
    * @param setIdReward Set reward amount at this ID in `InstaMemory` Contract.
  */
  function withdraw(
    string calldata gaugePoolName,
    uint amt,
    uint getId,
    uint setId,
    uint setIdCrv,
    uint setIdReward
  ) external payable {
    uint _amt = getUint(getId, amt);
    ICurveGaugeMapping curveGaugeMapping = ICurveGaugeMapping(getCurveGaugeMappingAddr());
    ICurveGaugeMapping.GaugeData memory curveGaugeData = curveGaugeMapping.gaugeMapping(
      bytes32(stringToBytes32(gaugePoolName))
    );
    require(curveGaugeData.gaugeAddress != address(0), "wrong-gauge-pool-name");
    IGauge gauge = IGauge(curveGaugeData.gaugeAddress);
    TokenInterface crv_token = TokenInterface(address(gauge.crv_token()));
    TokenInterface rewarded_token;
    Balances memory balances;

    _amt = _amt == uint(-1) ? gauge.balanceOf(address(this)) : _amt;
    balances.intialCRVBal = crv_token.balanceOf(address(this));

    if (curveGaugeData.rewardToken) {
      rewarded_token = TokenInterface(address(gauge.rewarded_token()));
      balances.intialRewardBal = rewarded_token.balanceOf(address(this));
    }

    IMintor(getCurveMintorAddr()).mint(curveGaugeData.gaugeAddress);
    gauge.withdraw(_amt);

    balances.finalCRVBal = crv_token.balanceOf(address(this));
    balances.crvRewardAmt = sub(balances.finalCRVBal, balances.intialCRVBal);

    setUint(setId, _amt);
    setUint(setIdCrv, balances.crvRewardAmt);

    if (curveGaugeData.rewardToken) {
      balances.finalRewardBal = rewarded_token.balanceOf(address(this));
      balances.rewardAmt = sub(balances.finalRewardBal, balances.intialRewardBal);
      setUint(setIdReward, balances.rewardAmt);
    }

    emitLogWithdraw(gaugePoolName, _amt, getId, setId);
    emitLogClaimedReward(gaugePoolName, balances.crvRewardAmt, balances.rewardAmt, setIdCrv, setIdReward);
  }

  /**
  * @dev Claim CRV Reward with Staked Reward token
    * @param gaugePoolName gauge pool name.
    * @param setId Set CRV reward amount at this ID in `InstaMemory` Contract.
    * @param setIdReward Set token reward amount at this ID in `InstaMemory` Contract.
  */
  function claimReward(
    string calldata gaugePoolName,
    uint setId,
    uint setIdReward
  ) external payable {
    ICurveGaugeMapping curveGaugeMapping = ICurveGaugeMapping(getCurveGaugeMappingAddr());
    ICurveGaugeMapping.GaugeData memory curveGaugeData = curveGaugeMapping.gaugeMapping(
      bytes32(stringToBytes32(gaugePoolName))
    );
    require(curveGaugeData.gaugeAddress != address(0), "wrong-gauge-pool-name");
    IMintor mintor = IMintor(getCurveMintorAddr());
    IGauge gauge = IGauge(curveGaugeData.gaugeAddress);
    TokenInterface crv_token = TokenInterface(address(gauge.crv_token()));
    TokenInterface rewarded_token;
    Balances memory balances;

    if (curveGaugeData.rewardToken) {
      rewarded_token = TokenInterface(address(gauge.rewarded_token()));
      balances.intialRewardBal = rewarded_token.balanceOf(address(this));
    }

    balances.intialCRVBal = crv_token.balanceOf(address(this));

    mintor.mint(curveGaugeData.gaugeAddress);

    balances.finalCRVBal = crv_token.balanceOf(address(this));
    balances.crvRewardAmt = sub(balances.finalCRVBal, balances.intialCRVBal);

    setUint(setId, balances.crvRewardAmt);

    if(curveGaugeData.rewardToken){
      balances.finalRewardBal = rewarded_token.balanceOf(address(this));
      balances.rewardAmt = sub(balances.finalRewardBal, balances.intialRewardBal);
      setUint(setIdReward, balances.rewardAmt);
    }

    emitLogClaimedReward(gaugePoolName, balances.crvRewardAmt, balances.rewardAmt, setId, setIdReward);
  }
}

contract ConnectCurveGauge is CurveGauge {
  string public name = "Curve-Gauge-v1.0";
}

