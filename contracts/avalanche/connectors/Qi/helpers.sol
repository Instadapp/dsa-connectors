pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { ComptrollerInterface, QiInterface, BenqiMappingInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Benqi Comptroller
     */
    ComptrollerInterface internal constant troller = ComptrollerInterface(0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4);

    /**
     * @dev Reward Token
     */
    QiInterface internal constant benqiToken = QiInterface(0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5);

    /**
     * @dev Benqi Mapping
     */
    BenqiMappingInterface internal constant qiMapping = BenqiMappingInterface(0xe19Fba29ac9BAACc1F584aEcD9C98B4F6fC58ba6);

    /**
     * @dev Benqi reward token type to show BENQI or AVAX
     */
    uint8 internal constant rewardQi = 0;
    uint8 internal constant rewardAvax = 1;

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