pragma solidity ^0.6.5;

import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface, OneProtoMappingInterface } from "./interface.sol";


abstract contract Helpers is DSMath, Basic {

    /**
     * @dev Return 1proto mapping Address
     */
    function getOneProtoMappingAddress() internal pure returns (address payable) {
        return 0x8d0287AFa7755BB5f2eFe686AA8d4F0A7BC4AE7F;
    }

    /**
     * @dev Return 1proto Address
     */
    function getOneProtoAddress() internal virtual view returns (address payable) {
        return payable(OneProtoMappingInterface(getOneProtoMappingAddress()).oneProtoAddress());
    }

    /**
     * @dev Return  1Inch Address
     */
    function getOneInchAddress() internal pure returns (address) {
        return 0x111111125434b319222CdBf8C261674aDB56F3ae;
    }

    /**
     * @dev Return 1inch swap function sig
     */
    function getOneInchSig() internal pure returns (bytes4) {
        return 0x90411a32;
    }

    function getSlippageAmt(
        TokenInterface _buyAddr,
        TokenInterface _sellAddr,
        uint _sellAmt,
        uint unitAmt
    ) internal view returns(uint _slippageAmt) {
        (uint _buyDec, uint _sellDec) = getTokensDec(_buyAddr, _sellAddr);
        uint _sellAmt18 = convertTo18(_sellDec, _sellAmt);
        _slippageAmt = convert18ToDec(_buyDec, wmul(unitAmt, _sellAmt18));
    }

    function convertToTokenInterface(address[] memory tokens) internal pure returns(TokenInterface[] memory) {
        TokenInterface[] memory _tokens = new TokenInterface[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            _tokens[i] = TokenInterface(tokens[i]);
        }
        return _tokens;
    }
}