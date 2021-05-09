pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import {AccessControl} from "./AccessControl.sol";

interface IndexInterface {
    function master() external view returns (address);
}

contract InstaMappings is AccessControl {
    IndexInterface public constant instaIndex =
        IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, instaIndex.master());
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, address(this));
    }

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
