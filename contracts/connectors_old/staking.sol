pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// import files from common directory
import { TokenInterface } from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

interface IStakingRewards {
  function stake(uint256 amount) external;
  function withdraw(uint256 amount) external;
  function getReward() external;
  function balanceOf(address) external view returns(uint);
}

interface SynthetixMapping {

  struct StakingData {
    address stakingPool;
    address stakingToken;
    address rewardToken;
  }

  function stakingMapping(bytes32) external view returns(StakingData memory);

}

contract StakingHelper is DSMath, Stores {
  /**
   * @dev Return InstaDApp Staking Mapping Addresses
   */
  function getMappingAddr() internal virtual view returns (address) {
    return 0x772590F33eD05b0E83553650BF9e75A04b337526; // InstaMapping Address
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

  /**
   * @dev Get staking data
   */
  function getStakingData(string memory stakingName)
  internal
  view
  returns (
    IStakingRewards stakingContract,
    TokenInterface stakingToken,
    TokenInterface rewardToken,
    bytes32 stakingType
  )
  {
    stakingType = stringToBytes32(stakingName);
    SynthetixMapping.StakingData memory stakingData = SynthetixMapping(getMappingAddr()).stakingMapping(stakingType);
    require(stakingData.stakingPool != address(0) && stakingData.stakingToken != address(0), "Wrong Staking Name");
    stakingContract = IStakingRewards(stakingData.stakingPool);
    stakingToken = TokenInterface(stakingData.stakingToken);
    rewardToken = TokenInterface(stakingData.rewardToken);
  }
}

contract Staking is StakingHelper {
  event LogDeposit(
    address indexed stakingToken,
    bytes32 indexed stakingType,
    uint256 amount,
    uint getId,
    uint setId
  );

  event LogWithdraw(
    address indexed stakingToken,
    bytes32 indexed stakingType,
    uint256 amount,
    uint getId,
    uint setId
  );

  event LogClaimedReward(
    address indexed rewardToken,
    bytes32 indexed stakingType,
    uint256 rewardAmt,
    uint setId
  );

  /**
  * @dev Deposit Token.
    * @param stakingPoolName staking token address.
    * @param amt staking token amount.
    * @param getId Get token amount at this ID from `InstaMemory` Contract.
    * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function deposit(
    string calldata stakingPoolName,
    uint amt,
    uint getId,
    uint setId
  ) external payable {
    uint _amt = getUint(getId, amt);
    (
      IStakingRewards stakingContract,
      TokenInterface stakingToken,
      ,
      bytes32 stakingType
    ) = getStakingData(stakingPoolName);

    _amt = _amt == uint(-1) ? stakingToken.balanceOf(address(this)) : _amt;

    stakingToken.approve(address(stakingContract), _amt);
    stakingContract.stake(_amt);

    setUint(setId, _amt);
    emit LogDeposit(address(stakingToken), stakingType, _amt, getId, setId);
    bytes32 _eventCode = keccak256("LogDeposit(address,bytes32,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(address(stakingToken), stakingType, _amt, getId, setId);
    emitEvent(_eventCode, _eventParam);
  }

  /**
  * @dev Withdraw Token.
    * @param stakingPoolName staking token address.
    * @param amt staking token amount.
    * @param getId Get token amount at this ID from `InstaMemory` Contract.
    * @param setIdAmount Set token amount at this ID in `InstaMemory` Contract.
    * @param setIdReward Set reward amount at this ID in `InstaMemory` Contract.
  */
  function withdraw(
    string calldata stakingPoolName,
    uint amt,
    uint getId,
    uint setIdAmount,
    uint setIdReward
  ) external payable {
    uint _amt = getUint(getId, amt);
    (
      IStakingRewards stakingContract,
      TokenInterface stakingToken,
      TokenInterface rewardToken,
      bytes32 stakingType
    ) = getStakingData(stakingPoolName);

    _amt = _amt == uint(-1) ? stakingContract.balanceOf(address(this)) : _amt;
    uint intialBal = rewardToken.balanceOf(address(this));
    stakingContract.withdraw(_amt);
    stakingContract.getReward();
    uint finalBal = rewardToken.balanceOf(address(this));

    uint rewardAmt = sub(finalBal, intialBal);

    setUint(setIdAmount, _amt);
    setUint(setIdReward, rewardAmt);

    emit LogWithdraw(address(stakingToken), stakingType, _amt, getId, setIdAmount);
    bytes32 _eventCodeWithdraw = keccak256("LogWithdraw(address,bytes32,uint256,uint256,uint256)");
    bytes memory _eventParamWithdraw = abi.encode(address(stakingToken), stakingType, _amt, getId, setIdAmount);
    emitEvent(_eventCodeWithdraw, _eventParamWithdraw);

    emit LogClaimedReward(address(rewardToken), stakingType, rewardAmt, setIdReward);
    bytes32 _eventCodeReward = keccak256("LogClaimedReward(address,bytes32,uint256,uint256)");
    bytes memory _eventParamReward = abi.encode(address(rewardToken), stakingType, rewardAmt, setIdReward);
    emitEvent(_eventCodeReward, _eventParamReward);
  }

  /**
  * @dev Claim Reward.
    * @param stakingPoolName staking token address.
    * @param setId Set reward amount at this ID in `InstaMemory` Contract.
  */
  function claimReward(
    string calldata stakingPoolName,
    uint setId
  ) external payable {
     (
      IStakingRewards stakingContract,
      ,
      TokenInterface rewardToken,
      bytes32 stakingType
    ) = getStakingData(stakingPoolName);

    uint intialBal = rewardToken.balanceOf(address(this));
    stakingContract.getReward();
    uint finalBal = rewardToken.balanceOf(address(this));

    uint rewardAmt = sub(finalBal, intialBal);

    setUint(setId, rewardAmt);
    emit LogClaimedReward(address(rewardToken), stakingType, rewardAmt, setId);
    bytes32 _eventCode = keccak256("LogClaimedReward(address,bytes32,uint256,uint256)");
    bytes memory _eventParam = abi.encode(address(rewardToken), stakingType, rewardAmt, setId);
    emitEvent(_eventCode, _eventParam);
  }
}

contract ConnectStaking is Staking {
  string public name = "Staking-v1.1";
}
