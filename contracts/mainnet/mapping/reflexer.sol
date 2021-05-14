pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface CollateralJoinInterface {
    function collateralType() external view returns (bytes32);
}

interface ConnectorsInterface {
    function chief(address) external view returns (bool);
}

interface IndexInterface {
    function master() external view returns (address);
}

interface MappingControllerInterface {
    function hasRole(address,address) external view returns (bool);
}
contract Helpers {
    // TODO: thrilok, verify this address
    ConnectorsInterface public constant connectors = ConnectorsInterface(0xFE2390DAD597594439f218190fC2De40f9Cf1179);
    IndexInterface public constant instaIndex = IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    // TODO: add address for MappingController
    MappingControllerInterface public constant mappingController = MappingControllerInterface(address(0));
    uint public version = 1;

    mapping (bytes32 => address) public collateralJoinMapping;

    event LogAddCollateralJoinMapping(address[] collateralJoin);
    
    modifier hasRoleOrIsChief {
        require(
            msg.sender == instaIndex.master() ||
                connectors.chief(msg.sender) ||
                mappingController.hasRole(address(this), msg.sender),
            "not-an-chief"
        );
        _;
    }    
    
    function addCollateralJoinMapping(address[] memory collateralJoins) public hasRoleOrIsChief {
        _addCollateralJoinMapping(collateralJoins);
    }

    function _addCollateralJoinMapping(address[] memory collateralJoins) internal {
        require(collateralJoins.length > 0, "No-CollateralJoin-Address");
        for(uint i = 0; i < collateralJoins.length; i++) {
            address collateralJoin = collateralJoins[i];
            bytes32 collateralType = CollateralJoinInterface(collateralJoin).collateralType();
            require(collateralJoinMapping[collateralType] == address(0), "CollateralJoin-Already-Added");
            collateralJoinMapping[collateralType] = collateralJoin;
        }
        emit LogAddCollateralJoinMapping(collateralJoins);
    }

}

contract GebMapping is Helpers {
    string constant public name = "Reflexer-Mapping-v1";
    
    constructor() public {
        address[] memory collateralJoins = new address[](1);
        collateralJoins[0] = 0x2D3cD7b81c93f188F3CB8aD87c8Acc73d6226e3A; // ETH-A Join contract address
        _addCollateralJoinMapping(collateralJoins); 
    }
}