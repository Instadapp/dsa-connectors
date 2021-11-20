pragma solidity ^0.7.0;


/**
 * @title QiDAo.
 * @dev Lending & Borrowing.
 * TODO Update doc Strings
 */

import "hardhat/console.sol";

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { erc20StablecoinInterface, maticStablecoinInterface } from "./interface.sol";

abstract contract QiDaoResolver is Events, Helpers {

    address constant internal MAI = 0xa3Fa99A148fA48D14Ed51d610c367C61876997F1;

    function createVault(address vaultAddress, uint256 setId) external payable  returns (string memory _eventName, bytes memory _eventParam) {
        erc20StablecoinInterface vault = erc20StablecoinInterface(vaultAddress);
        uint256 vaultId = vault.createVault();

        setUint(setId, vaultId);

        _eventName = "LogCreateVault(uint256, address)";
        _eventParam = abi.encode(vaultId, address(this));
    }

    function destroyVault(address vaultAddress, uint256 vaultId, uint256 getId)  external payable  returns (string memory _eventName, bytes memory _eventParam) {
        erc20StablecoinInterface vault = erc20StablecoinInterface(vaultAddress);
        uint256 _vaultId = getUint(getId, vaultId);
        vault.destroyVault(_vaultId);

        _eventName = "LogDestroyVault(uint256, address)";
        _eventParam = abi.encode(_vaultId, address(this));
    }


    /**
     * @dev Deposit ETH/ERC20_Token.
     * @notice Deposit a token to Aave v2 for lending / collaterization.
     * @param token The address of the token to deposit.(For MATIC: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
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
) external payable returns (string memory _eventName, bytes memory _eventParam) {

        uint _amt = getUint(getAmtId, amt);
        uint _vaultId = getUint(getVaultId, vaultId);

        bool isEth = token == maticAddr;

        if(isEth){
            maticStablecoinInterface vault = maticStablecoinInterface(vaultAddress);
            vault.depositCollateral{value: _amt}(_vaultId);
        }
        else {
            erc20StablecoinInterface vault = erc20StablecoinInterface(vaultAddress);
            TokenInterface tokenContract = TokenInterface(token);
            approve(tokenContract, address(vault), _amt);
            vault.depositCollateral(_vaultId, _amt);
        }

        setUint(setAmtId, _amt);
        setUint(getVaultId, _vaultId);

        _eventName = "LogDepositCollateral(uint256, uint256, uint256, uint256, uint256, uint256)";
        _eventParam = abi.encode(_vaultId, _amt, getVaultId, setVaultId, getAmtId, setAmtId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @notice Withdraw deposited token from Aave v2
     * @param token The address of the token to withdraw.(For MATIC: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
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
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getAmtId, amt);
        uint _vaultId = getUint(getVaultId, vaultId);

        bool isEth = token == maticAddr;

        uint initialBal;
        uint finalBal;

        if(isEth){
            initialBal = address(this).balance;
            maticStablecoinInterface vault = maticStablecoinInterface(vaultAddress);

            vault.withdrawCollateral(_vaultId, _amt);
            finalBal = address(this).balance;
        }
        else {
            TokenInterface tokenContract = TokenInterface(token);
            erc20StablecoinInterface vault = erc20StablecoinInterface(vaultAddress);

            initialBal = tokenContract.balanceOf(address(this));

            approve(tokenContract, address(vault), _amt);
            vault.withdrawCollateral(_vaultId, _amt);
            finalBal = tokenContract.balanceOf(address(this));
        }


        _amt = sub(finalBal, initialBal);

        setUint(setAmtId, _amt);

        _eventName = "LogWithdrawCollateral(uint256, uint256, uint256, uint256, uint256, uint256)";
        _eventParam = abi.encode(_vaultId, _amt, getVaultId, setVaultId, getAmtId, setAmtId);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @notice Borrow a token using Aave v2
     * @param amt The amount of the token to borrow.
     * @param getAmtId ID to retrieve amt.
     * @param setAmtId ID stores the amount of tokens borrowed.
    */
    function borrow(
        address vaultAddress,
        uint256 vaultId,
        uint256 amt,
        uint256 getVaultId,
        uint256 setVaultId,
        uint256 getAmtId,
        uint256 setAmtId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getAmtId, amt);
        uint _vaultId = getUint(getVaultId, vaultId);

        erc20StablecoinInterface vault = erc20StablecoinInterface(vaultAddress);
        vault.borrowToken(_vaultId, _amt);

        setUint(setAmtId, _amt);
        setUint(getVaultId, _vaultId);

        _eventName = "LogBorrow(uint256, uint256, uint256, uint256, uint256, uint256);";
        _eventParam = abi.encode(_vaultId, _amt, getVaultId, setVaultId, getAmtId, setAmtId);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @notice Payback debt owed.
     * @param amt The amount of the token to payback. (For max: `uint256(-1)`)
     * @param getAmtId ID to retrieve amt.
     * @param setAmtId ID stores the amount of tokens paid back.
    */
    function payback(
        address vaultAddress,
        uint256 vaultId,
        uint256 amt,
        uint256 getVaultId,
        uint256 setVaultId,
        uint256 getAmtId,
        uint256 setAmtId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getAmtId, amt);
        uint _vaultId = getUint(getVaultId, vaultId);

        erc20StablecoinInterface vault = erc20StablecoinInterface(vaultAddress);

        TokenInterface tokenContract = TokenInterface(MAI);

        approve(tokenContract, address(vault), _amt);

        vault.payBackToken(_vaultId, _amt);

        setUint(setAmtId, _amt);
        setUint(getVaultId, _vaultId);

        _eventName ="LogPayBack(uint256, uint256, uint256, uint256, uint256, uint256)";
        _eventParam = abi.encode(_vaultId, _amt, getVaultId, setVaultId, getAmtId, setAmtId);
    }
}

contract ConnectV2QiDaoPolygon is QiDaoResolver{
    string constant public name = "QiDao-v1";
}
