pragma solidity ^0.7.0;

/**
 * @title PoolTogether
 * @dev Deposit & Withdraw from PoolTogether
 */

 import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
 import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import { PrizePoolInterface, TokenFaucetInterface, TokenFaucetProxyFactoryInterface, PodInterface } from "./interface.sol";

import { TokenInterface } from "../../common/interfaces.sol";
import { Events } from "./events.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";

abstract contract PoolTogetherResolver is Events, DSMath, Basic {
    using SafeERC20 for IERC20;

    /**
     * @dev Deposit into Prize Pool
     * @notice Deposit assets into the Prize Pool in exchange for tokens
     * @param prizePool PrizePool address to deposit to
     * @param amount The amount of the underlying asset the user wishes to deposit. The Prize Pool contract should have been pre-approved by the caller to transfer the underlying ERC20 tokens.
     * @param controlledToken The address of the token that they wish to mint. For our default Prize Strategy this will either be the Ticket address or the Sponsorship address.  Those addresses can be looked up on the Prize Strategy.
     * @param referrer The address that should receive referral awards, if any.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */

    function depositTo(
        address prizePool,
        uint256 amount,
        address controlledToken,
        address referrer,
        uint256 getId,
        uint256 setId
    ) external payable returns ( string memory _eventName, bytes memory _eventParam) {
        uint _amount = getUint(getId, amount);

        PrizePoolInterface prizePoolContract = PrizePoolInterface(prizePool);
        address prizePoolToken = prizePoolContract.token();

        // Approve prizePool
        TokenInterface tokenContract = TokenInterface(prizePoolToken);
        _amount = _amount == uint256(-1) ? tokenContract.balanceOf(address(this)) : _amount;
        tokenContract.approve(prizePool, _amount);

        prizePoolContract.depositTo(address(this), _amount, controlledToken, referrer);

        setUint(setId, _amount);

        _eventName = "LogDepositTo(address,address,uint256,address,address,uint256, uint256)";
        _eventParam = abi.encode(address(prizePool), address(this), _amount, address(controlledToken), address(referrer), getId, setId);
    }

    /**
     * @dev Withdraw from Prize Pool
     * @notice Withdraw assets from the Prize Pool instantly.  A fairness fee may be charged for an early exit.
     * @param prizePool PrizePool address to deposit to
     * @param amount The amount of tokens to redeem for assets.
     * @param controlledToken The address of the token to redeem (i.e. ticket or sponsorship)
     * @param maximumExitFee The maximum early exit fee the caller is willing to pay. This prevents the Prize Strategy from changing the fee on the fly.  This should be pre-calculated by the calculateExitFee() fxn.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */

    function withdrawInstantlyFrom (
        address prizePool,
        uint256 amount,
        address controlledToken,
        uint256 maximumExitFee,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amount = getUint(getId, amount);

        PrizePoolInterface prizePoolContract = PrizePoolInterface(prizePool);

        TokenInterface ticketToken = TokenInterface(controlledToken);
        _amount = _amount == uint256(-1) ? ticketToken.balanceOf(address(this)) : _amount;

        prizePoolContract.withdrawInstantlyFrom(address(this), _amount, controlledToken, maximumExitFee);

        setUint(setId, _amount);

        _eventName = "LogWithdrawInstantlyFrom(address,address,uint256,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(prizePool), address(this), _amount, address(controlledToken), maximumExitFee, getId, setId);
    }

    /**
     * @dev Claim token from a Token Faucet
     * @notice Claim token from a Token Faucet
     * @param tokenFaucet TokenFaucet address
     * @param setId Set claimed amount at this ID in `InstaMemory` Contract.
    */
    function claim (
        address tokenFaucet,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        TokenFaucetInterface tokenFaucetContract = TokenFaucetInterface(tokenFaucet);

        uint256 claimed = tokenFaucetContract.claim(address(this));

        setUint(setId, claimed);

        _eventName = "LogClaim(address,address, uint256, uint256)";
        _eventParam = abi.encode(address(tokenFaucet), address(this), claimed, setId);
    }

    /**
     * @dev Runs claim on all passed comptrollers for a user.
     * @notice Runs claim on all passed comptrollers for a user.
     * @param tokenFaucetProxyFactory The TokenFaucetProxyFactory address
     * @param tokenFaucets The tokenFaucets to call claim on.
    */
    function claimAll (
        address tokenFaucetProxyFactory,
        TokenFaucetInterface[] calldata tokenFaucets
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        TokenFaucetProxyFactoryInterface tokenFaucetProxyFactoryContract = TokenFaucetProxyFactoryInterface(tokenFaucetProxyFactory);

        tokenFaucetProxyFactoryContract.claimAll(address(this), tokenFaucets);

        _eventName = "LogClaimAll(address,address,TokenFaucetInterface[])";
        _eventParam = abi.encode(address(tokenFaucetProxyFactory), address(this), tokenFaucets);
    }

    /**
     * @dev Deposit into Pod
     * @notice Deposit assets into the Pod in exchange for share tokens
     * @param prizePool PrizePool address to deposit to
     * @param pod Pod address to deposit to
     * @param tokenAmount The amount of tokens to deposit.  These are the same tokens used to deposit into the underlying prize pool.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function depositToPod(
        address prizePool,
        address pod,
        uint256 tokenAmount,
        uint256 getId,
        uint256 setId
    ) external payable returns ( string memory _eventName, bytes memory _eventParam) {
        uint _tokenAmount= getUint(getId, tokenAmount);

        PrizePoolInterface prizePoolContract = PrizePoolInterface(prizePool);
        address prizePoolToken = prizePoolContract.token();

        PodInterface podContract = PodInterface(pod);

        // Approve pod
        TokenInterface tokenContract = TokenInterface(prizePoolToken);
        _tokenAmount = _tokenAmount == uint256(-1) ? tokenContract.balanceOf(address(this)) : _tokenAmount;
        tokenContract.approve(pod, _tokenAmount);

        podContract.depositTo(address(this), _tokenAmount);

        setUint(setId, _tokenAmount);

        _eventName = "LogDepositToPod(address,address,address,uint256,uint256, uint256)";
        _eventParam = abi.encode(address(prizePool), address(pod), address(this), _tokenAmount, getId, setId);
    }

    /**
     * @dev Withdraw from shares from Pod
     * @notice Withdraws a users share of the prize pool.
     * @dev The function should first withdraw from the 'float'; i.e. the funds that have not yet been deposited.
     * @param pod Pod address
     * @param shareAmount The number of Pod shares to burn.
     * @param maxFee Max fee amount for withdrawl if amount isn't available in float.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */

    function withdrawFromPod (
        address pod,
        uint256 shareAmount,
        uint256 maxFee,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _shareAmount = getUint(getId, shareAmount);

        PodInterface podContract = PodInterface(pod);
        _shareAmount = _shareAmount == uint256(-1) ? podContract.balanceOf(address(this)) : _shareAmount;

        podContract.withdraw(_shareAmount, maxFee);

        setUint(setId, _shareAmount);

        _eventName = "LogWithdrawFromPod(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(pod), _shareAmount, maxFee, getId, setId);
    }
}

contract ConnectV2PoolTogether is PoolTogetherResolver {
    string public constant name = "PoolTogether-v1";
}