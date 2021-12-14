pragma solidity ^0.7.0;

/**
 * @title QiDAo.
 * @dev Lending & Borrowing.
 * TODO Update doc Strings
 */

import {Stores} from "../../common/stores.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

abstract contract QiDaoResolver is Events, Helpers {
    /**
     * @dev Create a vault
     * @notice Create a vault on QiDao
     * @param vaultAddress The address of the vault smart contract for the token/asset
     * @param setId ID of the created vault.
     */
    function createVault(address vaultAddress, uint256 setId)
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _vaultId = getVaultId(vaultAddress, setId);
        _eventName = "LogCreateVault(uint256,address)";
        _eventParam = abi.encode(_vaultId, address(this));
    }

    /**
     * @dev Destroy a specific vault
     * @notice Destroy a specific vault on QiDao
     * @param vaultAddress The address of the vault smart contract for the token/asset
     * @param vaultId The NFT ID which identifies the vault to be interacted with
     * @param getId ID to retrieve vaultId.
     */
    function destroyVault(
        address vaultAddress,
        uint256 vaultId,
        uint256 getId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _vaultId = _destroyVault(vaultAddress, vaultId, getId);
        _eventName = "LogDestroyVault(uint256,address)";
        _eventParam = abi.encode(_vaultId, address(this));
    }

    /**
     * @dev Deposit MATIC/ERC20_Token.
     * @notice Deposit a token to QiDao for lending / collaterization.
     * @param token The address of the token to deposit.(For MATIC: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param vaultAddress The address of the vault smart contract for the token/asset
     * @param vaultId The NFT ID which identifies the vault to be interacted with
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getVaultId ID to retrieve vaultId.
     * @param setVaultId ID stores the vault being interacted with.
     * @param getAmtId ID to retrieve amt.
     * @param setAmtId ID stores the amount of tokens withdrawn.
     */
    function deposit(
        address token,
        address vaultAddress,
        uint256 vaultId,
        uint256 amt,
        uint256 getVaultId,
        uint256 setVaultId,
        uint256 getAmtId,
        uint256 setAmtId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getAmtId, amt);
        uint256 _vaultId = getUint(getVaultId, vaultId);

        _deposit(token, vaultAddress, _vaultId, _amt);

        setUint(setAmtId, _amt);
        setUint(getVaultId, _vaultId);

        _eventName = "LogDepositCollateral(uint256,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            _vaultId,
            _amt,
            getVaultId,
            setVaultId,
            getAmtId,
            setAmtId
        );
    }

    /**
     * @dev Withdraw MATIC/ERC20_Token.
     * @notice Withdraw deposited token from QiDao
     * @param token The address of the token to deposit.(For MATIC: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param vaultAddress The address of the vault smart contract for the token/asset
     * @param vaultId The NFT ID which identifies the vault to be interacted with
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getVaultId ID to retrieve vaultId.
     * @param setVaultId ID stores the vault being interacted with.
     * @param getAmtId ID to retrieve amt.
     * @param setAmtId ID stores the amount of tokens withdrawn.
     */
    function withdraw(
        address token,
        address vaultAddress,
        uint256 vaultId,
        uint256 amt,
        uint256 getVaultId,
        uint256 setVaultId,
        uint256 getAmtId,
        uint256 setAmtId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getAmtId, amt);
        uint256 _vaultId = getUint(getVaultId, vaultId);

        (uint256 initialBal, uint256 finalBal) = _withdraw(token, vaultAddress, _vaultId, _amt);

        _amt = sub(finalBal, initialBal);

        setUint(setAmtId, _amt);

        _eventName = "LogWithdrawCollateral(uint256,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            _vaultId,
            _amt,
            getVaultId,
            setVaultId,
            getAmtId,
            setAmtId
        );
    }

    /**
     * @dev Borrow MAI.
     * @notice Borrow MAI from a specific vault on QiDao
     * @param amt The amount of the token to borrow.
     * @param vaultAddress The address of the vault smart contract for the token/asset
     * @param vaultId The NFT ID which identifies the vault to be interacted with
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getVaultId ID to retrieve vaultId.
     * @param setVaultId ID stores the vault being interacted with.
     * @param getAmtId ID to retrieve amt.
     * @param setAmtId ID stores the amount of tokens withdrawn.
     */
    function borrow(
        address vaultAddress,
        uint256 vaultId,
        uint256 amt,
        uint256 getVaultId,
        uint256 setVaultId,
        uint256 getAmtId,
        uint256 setAmtId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getAmtId, amt);
        uint256 _vaultId = getUint(getVaultId, vaultId);

        _borrow(vaultAddress, _vaultId, _amt);

        setUint(setAmtId, _amt);
        setUint(getVaultId, _vaultId);

        _eventName = "LogBorrow(uint256,uint256,uint256,uint256,uint256,uint256);";
        _eventParam = abi.encode(
            _vaultId,
            _amt,
            getVaultId,
            setVaultId,
            getAmtId,
            setAmtId
        );
    }

    /**
     * @dev Payback borrowed MAI.
     * @notice Payback MAI from a specific vault on QiDao
     * @param vaultAddress The address of the vault smart contract for the token/asset
     * @param vaultId The NFT ID which identifies the vault to be interacted with
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getVaultId ID to retrieve vaultId.
     * @param setVaultId ID stores the vault being interacted with.
     * @param getAmtId ID to retrieve amt.
     * @param setAmtId ID stores the amount of tokens withdrawn.
     */
    function payback(
        address vaultAddress,
        uint256 vaultId,
        uint256 amt,
        uint256 getVaultId,
        uint256 setVaultId,
        uint256 getAmtId,
        uint256 setAmtId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getAmtId, amt);
        uint256 _vaultId = getUint(getVaultId, vaultId);

        _payback(vaultAddress, _vaultId, _amt);

        setUint(setAmtId, _amt);
        setUint(getVaultId, _vaultId);

        _eventName = "LogPayBack(uint256,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            _vaultId,
            _amt,
            getVaultId,
            setVaultId,
            getAmtId,
            setAmtId
        );
    }
}

contract ConnectV2QiDaoPolygon is QiDaoResolver {
    string public constant name = "QiDao-v1";
}
