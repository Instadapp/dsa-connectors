pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { ComptrollerInterface, QiInterface, BenqiMappingInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Benqi Comptroller
     */
    ComptrollerInterface internal constant troller = ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    /**
     * @dev Reward Token
     */
    QiInterface internal constant benqiToken = QiInterface(0xc00e94Cb662C3520282E6f5717214004A7f26888);

    /**
     * @dev Benqi Mapping
     */
    BenqiMappingInterface internal constant qiMapping = BenqiMappingInterface(0xe7a85d0adDB972A4f0A4e57B698B37f171519e88);

    function getMergedQiTokens(
        string[] calldata supplyIds,
        string[] calldata borrowIds
    ) internal view returns (address[] memory qitokens, bool isBorrow, bool isSupply) {
        uint _supplyLen = supplyIds.length;
        uint _borrowLen = borrowIds.length;
        uint _totalLen = add(_supplyLen, _borrowLen);
        qitokens = new address[](_totalLen);

        if(_supplyLen > 0) {
            isSupply = true;
            for (uint i = 0; i < _supplyLen; i++) {
                (address token, address qiToken) = qiMapping.getMapping(supplyIds[i]);
                require(token != address(0) && qiToken != address(0), "invalid token/qitoken address");

                qitokens[i] = qiToken;
            }
        }

        if(_borrowLen > 0) {
            isBorrow = true;
            for (uint i = 0; i < _borrowLen; i++) {
                (address token, address qiToken) = qiMapping.getMapping(borrowIds[i]);
                require(token != address(0) && qiToken != address(0), "invalid token/qitoken address");

                qitokens[_supplyLen + i] = qiToken;
            }
        }
    }
}