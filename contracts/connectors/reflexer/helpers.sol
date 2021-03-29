pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { ManagerLike, CoinJoinInterface, SafeEngineLike, TaxCollectorLike } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Manager Interface
     */
    ManagerLike internal constant managerContract = ManagerLike(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);

    /**
     * @dev DAI Join
     */
    CoinJoinInterface internal constant daiJoinContract = CoinJoinInterface(0x9759A6Ac90977b93B58547b4A71c78317f391A28);

    /**
     * @dev Maker MCD Jug Address.
    */
    TaxCollectorLike internal constant mcdJug = TaxCollectorLike(0x19c0976f590D67707E62397C87829d896Dc0f1F1);

    /**
     * @dev Return Close Vault Address.
    */
    address internal constant giveAddr = 0x4dD58550eb15190a5B3DfAE28BB14EeC181fC267;

    /**
     * @dev Get Vault's ilk.
    */
    function getVaultData(uint vault) internal view returns (bytes32 ilk, address urn) {
        ilk = managerContract.collateralTypes(vault);
        urn = managerContract.safes(vault);
    }

    /**
     * @dev Gem Join address is ETH type collateral.
    */
    function isEth(address tknAddr) internal pure returns (bool) {
        return tknAddr == ethAddr ? true : false;
    }

    /**
     * @dev Get Vault Debt Amount.
    */
    function _getVaultDebt(
        address vat,
        bytes32 ilk,
        address urn
    ) internal view returns (uint wad) {
        (, uint rate,,,) = SafeEngineLike(vat).collateralTypes(ilk);
        (, uint art) = SafeEngineLike(vat).safes(ilk, urn);
        uint coin = SafeEngineLike(vat).coin(urn);

        uint rad = sub(mul(art, rate), coin);
        wad = rad / RAY;

        wad = mul(wad, RAY) < rad ? wad + 1 : wad;
    }

    /**
     * @dev Get Borrow Amount.
    */
    function _getBorrowAmt(
        address vat,
        address urn,
        bytes32 ilk,
        uint amt
    ) internal returns (int dart)
    {
        uint rate = mcdJug.taxSingle(ilk);
        uint coin = SafeEngineLike(vat).coin(urn);
        if (coin < mul(amt, RAY)) {
            dart = toInt(sub(mul(amt, RAY), coin) / rate);
            dart = mul(uint(dart), rate) < mul(amt, RAY) ? dart + 1 : dart;
        }
    }

    /**
     * @dev Get Payback Amount.
    */
    function _getWipeAmt(
        address vat,
        uint amt,
        address urn,
        bytes32 ilk
    ) internal view returns (int dart)
    {
        (, uint rate,,,) = SafeEngineLike(vat).collateralTypes(ilk);
        (, uint art) = SafeEngineLike(vat).safes(ilk, urn);
        dart = toInt(amt / rate);
        dart = uint(dart) <= art ? - dart : - toInt(art);
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
     * @dev Get vault ID. If `vault` is 0, get lastSAFEID opened vault.
    */
    function getVault(uint vault) internal view returns (uint _vault) {
        if (vault == 0) {
            require(managerContract.safeCount(address(this)) > 0, "no-vault-opened");
            _vault = managerContract.lastSAFEID(address(this));
        } else {
            _vault = vault;
        }
    }

}