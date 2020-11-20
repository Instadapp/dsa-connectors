pragma solidity ^0.6.0;

// import files from common directory
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";
import { TokenInterface } from "../common/interfaces.sol";

interface ICurve {
  function claim(address addr) external;
}

contract CurveVestingHelpers is Stores, DSMath {
  /**
  * @dev Return Curve Token Address
  */
  function getCurveTokenAddr() virtual internal view returns (address) {
    return 0xD533a949740bb3306d119CC777fa900bA034cd52;
  }

  /**
  * @dev Return Curve Vesting Address
  */
  function getCurveVestingAddr() virtual internal view returns (address) {
    return 0x575CCD8e2D300e2377B43478339E364000318E2c;
  }
}

contract CurveVestingProtocol is CurveVestingHelpers {
  event LogClaim(address account, uint256 claimAmount, uint256 getId, uint256 setId);

  /**
  * @dev Claim Curve DAO Token.
  * @param getId Get token amount at this ID from `InstaMemory` Contract.
  * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function claim(uint getId, uint setId) external{
    TokenInterface curveTokenContract = TokenInterface(getCurveTokenAddr());

    uint initialCurveBal = curveTokenContract.balanceOf(address(this));
    ICurve(getCurveVestingAddr()).claim(address(this));
    uint finalCurveBal = curveTokenContract.balanceOf(address(this));

    uint claimedAmt = sub(finalCurveBal, initialCurveBal);

    setUint(setId, claimedAmt);

    emit LogClaim(address(this), claimedAmt, getId, setId);
    bytes32 _eventCode = keccak256("LogClaim(address,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(address(this), claimedAmt, getId, setId);
    emitEvent(_eventCode, _eventParam);
  }
}

contract ConnectCurveVesting is CurveVestingProtocol {
  string public name = "Curve-vesting-v1";
}

