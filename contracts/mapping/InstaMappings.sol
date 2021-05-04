pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
interface IndexInterface {
    function master() external view returns (address);
}

contract InstaMappings is AccessControl {
    IndexInterface public constant instaIndex = IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    function setMaster() public {
        require(msg.sender == address(this), "msg.sender is not this contract");
        uint256 adminCount = getRoleMemberCount(DEFAULT_ADMIN_ROLE);
        require(adminCount == 1, "setMaster::Wrong-admin-count");
        address currentMaster = getRoleMember(DEFAULT_ADMIN_ROLE, 0);
        address master = instaIndex.master();
        
        if (currentMaster != master) {
            grantRole(DEFAULT_ADMIN_ROLE, master);
            revokeRole(DEFAULT_ADMIN_ROLE, currentMaster);
        }

        adminCount = getRoleMemberCount(DEFAULT_ADMIN_ROLE);
        require(adminCount == 1, "setMaster::Wrong-admin-count");
        require(hasRole(DEFAULT_ADMIN_ROLE, master), "setMaster::InstaIndex-master-not-set");
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, instaIndex.master());
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, address(this));
    }

    function getMappingContractRole(address mappingContract) public pure returns (bytes32 role){
        assembly {
            role := mload(add(mappingContract, 32))
        }
    }

    function hasRole(address mappingAddr, address account) public view returns (bool) {
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