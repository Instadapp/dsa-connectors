// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface IndexInterface {
    function master() external view returns (address);
}

interface ConnectorsInterface {
    function chief(address) external view returns (bool);
}

contract InstaMappingController is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    mapping(address => EnumerableSet.AddressSet) private _roles;

    IndexInterface public constant instaIndex =
        IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    ConnectorsInterface public constant connectors =
        ConnectorsInterface(0x97b0B3A8bDeFE8cB9563a3c610019Ad10DB8aD11); // InstaConnectorsV2


    /**
     * @dev Emitted when `account` is granted `role`.
     */
    event RoleGranted(address indexed role, address indexed account);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the insta master
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        address indexed role,
        address indexed account,
        address indexed sender
    );

    modifier onlyMaster {
        require(
            instaIndex.master() == _msgSender() || connectors.chief(_msgSender()),
            "MappingController: sender must be master or chief"
        );
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(address role, address account) public view returns (bool) {
        return _roles[role].contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(address role) public view returns (uint256) {
        return _roles[role].length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(address role, uint256 index)
        public
        view
        returns (address)
    {
        return _roles[role].at(index);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must be the master.
     */
    function grantRole(address role, address account)
        public
        virtual
        onlyMaster
    {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must be the master.
     */
    function revokeRole(address role, address account)
        public
        virtual
        onlyMaster
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(address role, address account) public virtual {
        require(
            account == _msgSender(),
            "MappingController: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(address role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _grantRole(address role, address account) private {
        if (_roles[role].add(account)) {
            emit RoleGranted(role, account);
        }
    }

    function _revokeRole(address role, address account) private {
        if (_roles[role].remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
