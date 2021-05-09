pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import {InstaAccessControl} from "./InstaAccessControl.sol";

contract InstaMappings is InstaAccessControl {
    function getMappingContractRole(address mappingContract)
        public
        pure
        returns (bytes32 role)
    {
        bytes memory encoded = abi.encode(mappingContract);
        assembly {
            role := mload(add(encoded, 32))
        }
    }

    function hasRole(address mappingAddr, address account)
        public
        view
        returns (bool)
    {
        return super.hasRole(getMappingContractRole(mappingAddr), account);
    }

    function grantRole(address mappingAddr, address account) public {
        super.grantRole(getMappingContractRole(mappingAddr), account);
    }

    function revokeRole(address mappingAddr, address account) public {
        super.revokeRole(getMappingContractRole(mappingAddr), account);
    }

    function renounceRole(address mappingAddr, address account) public {
        super.renounceRole(getMappingContractRole(mappingAddr), account);
    }
}
