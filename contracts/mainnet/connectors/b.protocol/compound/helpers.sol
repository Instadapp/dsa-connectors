pragma solidity ^0.7.0;

import { DSMath } from "./../../../common/math.sol";
import { Basic } from "./../../../common/basic.sol";
import { ComptrollerInterface, CompoundMappingInterface, BComptrollerInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Compound Comptroller
     */
    ComptrollerInterface internal constant troller = ComptrollerInterface(0x9dB10B9429989cC13408d7368644D4A1CB704ea3);

    /**
     * @dev Compound Mapping
     */
    CompoundMappingInterface internal constant compMapping = CompoundMappingInterface(0xe7a85d0adDB972A4f0A4e57B698B37f171519e88);

    /**
     * @dev B.Compound Mapping
     */
    function getMapping(string calldata tokenId) public returns(address token, address btoken) {
        address ctoken;
        (token, ctoken) = compMapping.getMapping(tokenId);
        btoken = BComptrollerInterface(address(troller)).c2b(ctoken);
    }
}
