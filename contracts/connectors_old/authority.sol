pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/**
 * @title ConnectAuth.
 * @dev Connector For Adding Authorities.
 */

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
}

interface EventInterface {
    function emitEvent(uint _connectorType, uint _connectorID, bytes32 _eventCode, bytes calldata _eventData) external;
}

interface ListInterface {
    struct UserLink {
        uint64 first;
        uint64 last;
        uint64 count;
    }

    struct UserList {
        uint64 prev;
        uint64 next;
    }

    struct AccountLink {
        address first;
        address last;
        uint64 count;
    }

    struct AccountList {
        address prev;
        address next;
    }

    function accounts() external view returns (uint);
    function accountID(address) external view returns (uint64);
    function accountAddr(uint64) external view returns (address);
    function userLink(address) external view returns (UserLink memory);
    function userList(address, uint64) external view returns (UserList memory);
    function accountLink(uint64) external view returns (AccountLink memory);
    function accountList(uint64, address) external view returns (AccountList memory);

}


contract Basics {

    /**
     * @dev Return InstaEvent Address.
     */
    function getEventAddr() internal pure returns (address) {
        return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97;
    }

    /**
     * @dev Return InstaList Address.
    */
    function getListAddr() internal pure returns (address) {
        return 0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb;
    }

     /**
     * @dev Connector ID and Type.
     */
    function connectorID() public pure returns(uint _type, uint _id) {
        (_type, _id) = (1, 37);
    }

}

contract Helpers is Basics {
    function checkAuthCount() internal view returns (uint count) {
        ListInterface listContract = ListInterface(getListAddr());
        uint64 accountId = listContract.accountID(address(this));
        count = listContract.accountLink(accountId).count;
    }
}

contract Auth is Helpers {

    event LogAddAuth(address indexed _msgSender, address indexed _authority);
    event LogRemoveAuth(address indexed _msgSender, address indexed _authority);

    /**
     * @dev Add New authority
     * @param authority authority Address.
     */
    function add(address authority) external payable {
        AccountInterface(address(this)).enable(authority);

        emit LogAddAuth(msg.sender, authority);

        bytes32 _eventCode = keccak256("LogAddAuth(address,address)");
        bytes memory _eventParam = abi.encode(msg.sender, authority);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Remove authority
     * @param authority authority Address.
     */
    function remove(address authority) external payable {
        require(checkAuthCount() > 1, "Removing-all-authorities");
        AccountInterface(address(this)).disable(authority);

        emit LogRemoveAuth(msg.sender, authority);

        bytes32 _eventCode = keccak256("LogRemoveAuth(address,address)");
        bytes memory _eventParam = abi.encode(msg.sender, authority);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

}


contract ConnectAuth is Auth {
    string public constant name = "Auth-v1";
}