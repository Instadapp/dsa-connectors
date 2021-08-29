pragma solidity ^0.7.0;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { TokenInterface } from "./../../../common/interfaces.sol";
import { BManagerLike, DaiJoinInterface, PotLike, VatLike, JugLike } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Manager Interface
     */
    BManagerLike internal constant managerContract = BManagerLike(0x3f30c2381CD8B917Dd96EB2f1A4F96D91324BBed);

    /**
     * @dev DAI Join
     */
    DaiJoinInterface internal constant daiJoinContract = DaiJoinInterface(0x9759A6Ac90977b93B58547b4A71c78317f391A28);

    /**
     * @dev Pot
     */
    PotLike internal constant potContract = PotLike(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);

    /**
     * @dev Maker MCD Jug Address.
    */
    JugLike internal constant mcdJug = JugLike(0x19c0976f590D67707E62397C87829d896Dc0f1F1);

    /**
     * @dev Return Close Vault Address.
    */
    address internal constant giveAddr = 0x4dD58550eb15190a5B3DfAE28BB14EeC181fC267;

    /**
     * @dev Get Vault's ilk.
    */
    function getVaultData(uint vault) internal view returns (bytes32 ilk, address urn) {
        ilk = managerContract.ilks(vault);
        urn = managerContract.urns(vault);
    }

    /**
     * @dev Gem Join address is ETH type collateral.
    */
    function isEth(address tknAddr) internal pure returns (bool) {
        return tknAddr == wethAddr ? true : false;
    }

    /**
     * @dev Get Vault Debt Amount.
    */
    function _getVaultDebt(
        address vat,
        bytes32 ilk,
        address urn,
        uint vault
    ) internal view returns (uint wad) {
        (, uint rate,,,) = VatLike(vat).ilks(ilk);
        (, uint art) = VatLike(vat).urns(ilk, urn);
        uint cushion = managerContract.cushion(vault);        
        art = add(art, cushion);
        uint dai = VatLike(vat).dai(urn);

        uint rad = sub(mul(art, rate), dai);
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
        uint rate = mcdJug.drip(ilk);
        uint dai = VatLike(vat).dai(urn);
        if (dai < mul(amt, RAY)) {
            dart = toInt(sub(mul(amt, RAY), dai) / rate);
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
        bytes32 ilk,
        uint vault
    ) internal view returns (int dart)
    {
        (, uint rate,,,) = VatLike(vat).ilks(ilk);
        (, uint art) = VatLike(vat).urns(ilk, urn);
        uint cushion = managerContract.cushion(vault);        
        art = add(art, cushion);        
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
     * @dev Get vault ID. If `vault` is 0, get last opened vault.
    */
    function getVault(uint vault) internal view returns (uint _vault) {
        if (vault == 0) {
            require(managerContract.count(address(this)) > 0, "no-vault-opened");
            _vault = managerContract.last(address(this));
        } else {
            _vault = vault;
        }
    }

}