pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { 
    ManagerLike, 
    CoinJoinInterface, 
    SafeEngineLike, 
    TaxCollectorLike, 
    TokenJoinInterface,
    GebMapping 
} from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Manager Interface
     */
    ManagerLike internal constant managerContract = ManagerLike(0xEfe0B4cA532769a3AE758fD82E1426a03A94F185);

    /**
     * @dev Coin Join
     */
    CoinJoinInterface internal constant coinJoinContract = CoinJoinInterface(0x0A5653CCa4DB1B6E265F47CAf6969e64f1CFdC45);

    /**
     * @dev Reflexer Tax collector Address.
    */
    TaxCollectorLike internal constant taxCollectorContract = TaxCollectorLike(0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB);

    /**
     * @dev Return Close Safe Address.
    */
    address internal constant giveAddr = 0x4dD58550eb15190a5B3DfAE28BB14EeC181fC267;

     /**
     * @dev Return Reflexer mapping Address.
     */
    function getGebMappingAddress() internal pure returns (address) {
        return 0x573e5132693C046D1A9F75Bac683889164bA41b4;
    }

    function getCollateralJoinAddress(bytes32 collateralType) internal view returns (address) {
        return GebMapping(getGebMappingAddress()).collateralJoinMapping(collateralType);
    }

    /**
     * @dev Get Safe's collateral type.
    */
    function getSafeData(uint safe) internal view returns (bytes32 collateralType, address handler) {
        collateralType = managerContract.collateralTypes(safe);
        handler = managerContract.safes(safe);
    }

    /**
     * @dev Collateral Join address is ETH type collateral.
    */
    function isEth(address tknAddr) internal pure returns (bool) {
        return tknAddr == wethAddr ? true : false;
    }

    /**
     * @dev Get Safe Debt Amount.
    */
    function _getSafeDebt(
        address safeEngine,
        bytes32 collateralType,
        address handler
    ) internal view returns (uint wad) {
        (, uint rate,,,) = SafeEngineLike(safeEngine).collateralTypes(collateralType);
        (, uint debt) = SafeEngineLike(safeEngine).safes(collateralType, handler);
        uint coin = SafeEngineLike(safeEngine).coinBalance(handler);

        uint rad = sub(mul(debt, rate), coin);
        wad = rad / RAY;

        wad = mul(wad, RAY) < rad ? wad + 1 : wad;
    }

    /**
     * @dev Get Borrow Amount.
    */
    function _getBorrowAmt(
        address safeEngine,
        address handler,
        bytes32 collateralType,
        uint amt
    ) internal returns (int deltaDebt)
    {
        uint rate = taxCollectorContract.taxSingle(collateralType);
        uint coin = SafeEngineLike(safeEngine).coinBalance(handler);
        if (coin < mul(amt, RAY)) {
            deltaDebt = toInt(sub(mul(amt, RAY), coin) / rate);
            deltaDebt = mul(uint(deltaDebt), rate) < mul(amt, RAY) ? deltaDebt + 1 : deltaDebt;
        }
    }

    /**
     * @dev Get Payback Amount.
    */
    function _getWipeAmt(
        address safeEngine,
        uint amt,
        address handler,
        bytes32 collateralType
    ) internal view returns (int deltaDebt)
    {
        (, uint rate,,,) = SafeEngineLike(safeEngine).collateralTypes(collateralType);
        (, uint debt) = SafeEngineLike(safeEngine).safes(collateralType, handler);
        deltaDebt = toInt(amt / rate);
        deltaDebt = uint(deltaDebt) <= debt ? - deltaDebt : - toInt(debt);
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
     * @dev Get safe ID. If `safe` is 0, get lastSAFEID opened safe.
    */
    function getSafe(uint safe) internal view returns (uint _safe) {
        if (safe == 0) {
            require(managerContract.safeCount(address(this)) > 0, "no-safe-opened");
            _safe = managerContract.lastSAFEID(address(this));
        } else {
            _safe = safe;
        }
    }

}