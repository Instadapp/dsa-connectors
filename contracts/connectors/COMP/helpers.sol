pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { ComptrollerInterface, COMPInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Compound Comptroller
     */
    ComptrollerInterface internal constant troller = ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    /**
     * @dev COMP Token
     */
    COMPInterface internal constant compToken = COMPInterface(0xc00e94Cb662C3520282E6f5717214004A7f26888);

    function mergeTokenArr(address[] memory supplyTokens, address[] memory borrowTokens)
        internal
        view
        returns (address[] memory ctokens, bool isBorrow, bool isSupply)
    {
         uint _supplyLen = supplyTokens.length;
        uint _borrowLen = borrowTokens.length;
        uint _totalLen = add(_supplyLen, _borrowLen);
        ctokens = new address[](_totalLen);
        isBorrow;
        isSupply;
        if(_supplyLen > 0) {
            for (uint i = 0; i < _supplyLen; i++) {
                ctokens[i] = instaMapping.cTokenMapping(supplyTokens[i]);
            }
            isSupply = true;
        }

        if(_borrowLen > 0) {
            for (uint i = 0; i < _borrowLen; i++) {
                ctokens[_supplyLen + i] = instaMapping.cTokenMapping(borrowTokens[i]);
            }
            isBorrow = true;
        }
    }
}