pragma solidity ^0.7.0;

/**
 * @title PoolTogether V4
 * @dev Deposit & Withdraw from PoolTogether V4
 */

 import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
 import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import { PrizePoolInterface, TicketInterface, PrizeDistributorInterface } from "./interface.sol";

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Events } from "./events.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";

abstract contract PoolTogetherV4Resolver is Events, DSMath, Basic {
    using SafeERC20 for IERC20;

    /**
     * @dev Deposit into Prize Pool without a delegate
     * @notice Deposit assets into the Prize Pool in exchange for tokens
     * @param prizePool PrizePool address to deposit to
     * @param amount The amount of the underlying asset the user wishes to deposit. The Prize Pool contract should have been pre-approved by the caller to transfer the underlying ERC20 tokens.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */

    function depositTo(
        address prizePool,
        uint256 amount,
        uint256 getId,
        uint256 setId
    ) external payable returns ( string memory _eventName, bytes memory _eventParam) {
        uint _amount = getUint(getId, amount);

        PrizePoolInterface prizePoolContract = PrizePoolInterface(prizePool);
        address prizePoolToken = prizePoolContract.getToken();

        bool isEth = prizePoolToken == wethAddr;
        TokenInterface tokenContract = TokenInterface(prizePoolToken);

        if (isEth) {
            _amount = _amount == uint256(-1) ? address(this).balance : _amount;
            convertEthToWeth(isEth, tokenContract, _amount);
        } else {
            _amount = _amount == uint256(-1) ? tokenContract.balanceOf(address(this)) : _amount;
        }

        // Approve prizePool
        approve(tokenContract, prizePool, _amount);

        prizePoolContract.depositTo(address(this), _amount);

        setUint(setId, _amount);

        _eventName = "LogDepositTo(address, address,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(prizePool), address(this), _amount, getId, setId);
    }

    /**
     * @dev Deposit into Prize Pool and delegate 
     * @notice Deposit assets into the Prize Pool in exchange for tokens, then sets the delegate on behalf of the caller.
     * @param prizePool PrizePool address to deposit to
     * @param amount The amount of the underlying asset the user wishes to deposit. The Prize Pool contract should have been pre-approved by the caller to transfer the underlying ERC20 tokens.
     * @param delegateTo The address to delegate to for the caller 
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */

    function depositToAndDelegate(
        address prizePool,
        uint256 amount,
        address delegateTo,
        uint256 getId,
        uint256 setId
    ) external payable returns ( string memory _eventName, bytes memory _eventParam) {
        uint _amount = getUint(getId, amount);

        PrizePoolInterface prizePoolContract = PrizePoolInterface(prizePool);
        address prizePoolToken = prizePoolContract.getToken();

        bool isEth = prizePoolToken == wethAddr;
        TokenInterface tokenContract = TokenInterface(prizePoolToken);

        if (isEth) {
            _amount = _amount == uint256(-1) ? address(this).balance : _amount;
            convertEthToWeth(isEth, tokenContract, _amount);
        } else {
            _amount = _amount == uint256(-1) ? tokenContract.balanceOf(address(this)) : _amount;
        }

        // Approve prizePool
        approve(tokenContract, prizePool, _amount);

        prizePoolContract.depositToAndDelegate(address(this), _amount,delegateTo);

        setUint(setId, _amount);

        _eventName = "LogDepositToDelegate(address, address,uint256,address,uint256,uint256)";
        _eventParam = abi.encode(address(prizePool), address(this), _amount, address(delegateTo), getId, setId);
    }

    /**
     * @dev Withdraw from Prize Pool
     * @notice Withdraw assets from the Prize Pool instantly.
     * @param prizePool PrizePool address to withdraw from
     * @param amount The amount of tokens to redeem for assets.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */

    function withdrawFrom (
        address prizePool,
        uint256 amount,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amount = getUint(getId, amount);

        PrizePoolInterface prizePoolContract = PrizePoolInterface(prizePool);
        address prizePoolToken = prizePoolContract.getToken();
        TokenInterface tokenContract = TokenInterface(prizePoolToken);

        // TokenInterface ticketToken = TokenInterface(controlledToken);
        _amount = _amount == uint256(-1) ? tokenContract.balanceOf(address(this)) : _amount;

        _amount = prizePoolContract.withdrawFrom(address(this), _amount);

        convertWethToEth(prizePoolToken == wethAddr, tokenContract, _amount);

        setUint(setId, _amount);

        _eventName = "LogWithdrawFrom(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(prizePool), address(this), _amount, getId, setId);
    }

    /**
     * @dev Delegate time-weighted average balances to an alternative address.
     * @dev Transfers (including mints) trigger the storage of a TWAB in delegate(s) account, instead of the
     *         targetted sender and/or recipient address(s).
     * @dev    To reset the delegate, pass the zero address (0x000.000) as `to` parameter.
     * @notice Delegate time-weighted average balances to an alternative address.
     * @param ticket Prizepool ticket address
     * @param to Recipient of delegated TWAB.
    */

    function delegate (
        address ticket,
        address to
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        TicketInterface ticketContract = TicketInterface(ticket);
        ticketContract.delegate(to);

        _eventName = "LogDelegated(address,address,address)";
        _eventParam = abi.encode(address(ticket), address(this), address(to));
    }

     /**
      * @notice Claim prize payout(s) by submitting valud drawId(s) and winning pick indice(s). The user address
                is used as the "seed" phrase to generate random numbers.
      * @dev    The claim function is public and any wallet may execute claim on behalf of another user.
                Prizes are always paid out to the designated user account and not the caller (msg.sender).
                Claiming prizes is not limited to a single transaction. Reclaiming can be executed
                subsequentially if an "optimal" prize was not included in previous claim pick indices. The
                payout difference for the new claim is calculated during the award process and transfered to user.
      * @param prizeDistributor PrizeDistributor address
      * @param drawIds Draw IDs from global DrawBuffer reference
      * @param data    The data to pass to the draw calculator
      * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */

    function claim(
        address prizeDistributor,
        uint32[] calldata drawIds,
        bytes calldata data,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {

        PrizeDistributorInterface prizeDistributorContract = PrizeDistributorInterface(prizeDistributor);
        uint256 payout = prizeDistributorContract.claim(address(this), drawIds, data);

        setUint(setId, payout);

        _eventName = "LogClaim(address,address,uint32[],bytes,uint256,uint256)";
        _eventParam = abi.encode(address(prizeDistributor), address(this), drawIds, data, payout, setId);
    }
}

contract ConnectV2PoolTogetherV4 is PoolTogetherV4Resolver {
    string public constant name = "PoolTogetherV4-v1";
}