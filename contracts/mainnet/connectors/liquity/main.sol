pragma solidity ^0.7.0;

/**
 * @title Liquity.
 * @dev Lending & Borrowing.
 */
import "hardhat/console.sol";

import { BorrowerOperationsLike, TroveManagerLike, StabilityPoolLike, StakingLike } from "./interface.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract LiquityResolver is Events, Helpers {
    BorrowerOperationsLike internal constant borrowerOperations =
        BorrowerOperationsLike(0x24179CD81c9e782A4096035f7eC97fB8B783e007);
    TroveManagerLike internal constant troveManager =
        TroveManagerLike(0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4bb2);
    StabilityPoolLike internal constant stabilityPool =
        StabilityPoolLike(0x66017D22b0f8556afDd19FC67041899Eb65a21bb);
    StakingLike internal constant staking =
        StakingLike(0x4f9Fbb3f1E99B56e0Fe2892e623Ed36A76Fc605d);

    struct AdjustTrove {
        uint maxFeePercentage;
        uint withdrawAmount;
        uint depositAmount;
        uint borrowAmount;
        uint repayAmount;
        bool isBorrow;
    }

    constructor() {
        console.log("Liquity Connector contract deployed at", address(this));
    }

    /* Begin: Trove */

    /**
     * @dev Deposit native ETH and borrow LUSD
     * @notice Opens a Trove by depositing ETH and borrowing LUSD
     * @param depositAmount The amount of ETH to deposit
     * @param maxFeePercentage The maximum borrow fee that this transaction should permit 
     * @param borrowAmount The amount of LUSD to borrow
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove will now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove will now sit in the ordered Trove list
     * @param getId Optional storage slot to retrieve ETH instead of receiving it from msg.value
     * @param setId Optional storage slot to store the LUSD borrowed against
    */
    function open(
        uint depositAmount,
        uint maxFeePercentage,
        uint borrowAmount,
        address upperHint,
        address lowerHint,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        // User can either send ETH directly or have it collected from a previous spell
        depositAmount = getUint(getId, depositAmount);

        borrowerOperations.openTrove{value: depositAmount}(
            maxFeePercentage,
            borrowAmount,
            upperHint,
            lowerHint
        );

        // Allow other spells to use the borrowed amount
        setUint(setId, borrowAmount);
        _eventName = "LogOpen(address,uint,uint,uint,uint,uint)";
        _eventParam = abi.encode(msg.sender, maxFeePercentage, depositAmount, borrowAmount, getId, setId);
    }

    /**
     * @dev Repay LUSD debt from the DSA account's LUSD balance, and withdraw ETH to DSA
     * @notice Closes a Trove by repaying LUSD debt
     * @param setId Optional storage slot to store the ETH withdrawn from the Trove
    */
    function close(uint setId) external returns (string memory _eventName, bytes memory _eventParam) {
        uint collateral = troveManager.getTroveColl(address(this));
        borrowerOperations.closeTrove();

        // Allow other spells to use the collateral released from the Trove
        setUint(setId, collateral);
         _eventName = "LogClose(address,uint)";
        _eventParam = abi.encode(msg.sender, setId);
    }

    /**
     * @dev Deposit ETH to Trove
     * @notice Increase Trove collateral (collateral Top up)
     * @param amount Amount of ETH to deposit into Trove
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove will now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove will now sit in the ordered Trove list
     * @param getId Optional storage slot to retrieve the ETH from
    */
    function deposit(
        uint amount,
        address upperHint,
        address lowerHint,
        uint getId
    ) external payable returns (string memory _eventName, bytes memory _eventParam)  {
        amount = getUint(getId, amount);
        borrowerOperations.addColl{value: amount}(upperHint, lowerHint);
        _eventName = "LogDeposit(address,uint,uint)";
        _eventParam = abi.encode(msg.sender, amount, getId);
    }

    /**
     * @dev Withdraw ETH from Trove
     * @notice Move Trove collateral from Trove to DSA
     * @param amount Amount of ETH to move from Trove to DSA
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove will now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove will now sit in the ordered Trove list
     * @param setId Optional storage slot to store the withdrawn ETH in
    */
   function withdraw(
        uint amount,
        address upperHint,
        address lowerHint,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam)  {
        borrowerOperations.withdrawColl(amount, upperHint, lowerHint);

        setUint(setId, amount);
        _eventName = "LogWithdraw(address,uint,uint)";
        _eventParam = abi.encode(msg.sender, amount, setId);
    }
    
    /**
     * @dev Mints LUSD tokens
     * @notice Borrow LUSD via an existing Trove
     * @param maxFeePercentage The maximum borrow fee that this transaction should permit 
     * @param amount Amount of LUSD to borrow
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove will now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove will now sit in the ordered Trove list
     * @param setId Optional storage slot to store the borrowed LUSD in
    */
    function borrow(
        uint maxFeePercentage,
        uint amount,
        address upperHint,
        address lowerHint,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam)  {
        borrowerOperations.withdrawLUSD(maxFeePercentage, amount, upperHint, lowerHint);

        setUint(setId, amount); // TODO: apply fee / get exact amount borrowed (with the fee applied)
        _eventName = "LogBorrow(address,uint,uint)";
        _eventParam = abi.encode(msg.sender, amount, setId);
    }

    /**
     * @dev Send LUSD to repay debt
     * @notice Repay LUSD Trove debt
     * @param amount Amount of LUSD to repay
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove will now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove will now sit in the ordered Trove list
     * @param getId Optional storage slot to retrieve the LUSD from
    */
    function repay(
        uint amount,
        address upperHint,
        address lowerHint,
        uint getId
    ) external payable returns (string memory _eventName, bytes memory _eventParam)  {
        amount = getUint(getId, amount);
        borrowerOperations.repayLUSD(amount, upperHint, lowerHint);
        _eventName = "LogRepay(address,uint,uint)";
        _eventParam = abi.encode(msg.sender, amount, getId);
    }

    /**
     * @dev Increase or decrease Trove ETH collateral and LUSD debt in one transaction
     * @notice Adjust Trove debt and/or collateral
     * @param maxFeePercentage The maximum borrow fee that this transaction should permit 
     * @param withdrawAmount Amount of ETH to withdraw
     * @param depositAmount Amount of ETH to deposit
     * @param borrowAmount Amount of LUSD to borrow
     * @param repayAmount Amount of LUSD to repay
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove will now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove will now sit in the ordered Trove list
     * @param getDepositId Optional storage slot to retrieve the ETH to deposit
     * @param setWithdrawId Optional storage slot to store the withdrawn ETH to
     * @param getRepayId Optional storage slot to retrieve the LUSD to repay
     * @param setBorrowId Optional storage slot to store the LUSD borrowed
    */
    function adjust(
        uint maxFeePercentage,
        uint withdrawAmount,
        uint depositAmount,
        uint borrowAmount,
        uint repayAmount,
        address upperHint,
        address lowerHint,
        uint getDepositId,
        uint setWithdrawId,
        uint getRepayId,
        uint setBorrowId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        AdjustTrove memory adjustTrove;

        adjustTrove.maxFeePercentage = maxFeePercentage;
        adjustTrove.withdrawAmount = withdrawAmount;
        adjustTrove.depositAmount = getUint(getDepositId, depositAmount);
        adjustTrove.borrowAmount = borrowAmount;
        adjustTrove.repayAmount = getUint(getRepayId, repayAmount);
        adjustTrove.isBorrow = borrowAmount > 0;

        borrowerOperations.adjustTrove{value: depositAmount}(
            adjustTrove.maxFeePercentage,
            adjustTrove.withdrawAmount,
            adjustTrove.borrowAmount,
            adjustTrove.isBorrow,
            upperHint,
            lowerHint
        );
        
        // Allow other spells to use the withdrawn collateral
        setUint(setWithdrawId, withdrawAmount);

        // Allow other spells to use the borrowed amount
        setUint(setBorrowId, borrowAmount);

        _eventName = "LogAdjust(address,uint,uint,uint,uint,uint,uint,uint,uint,uint)";
        _eventParam = abi.encode(msg.sender, maxFeePercentage, depositAmount, borrowAmount, getDepositId, setWithdrawId, getRepayId, setBorrowId);
    }

    /**
     * @dev Withdraw remaining ETH balance from user's redeemed Trove to their DSA
     * @notice Claim remaining collateral from Trove
    */
    function claimCollateralFromRedemption() external returns(string memory _eventName, bytes memory _eventParam) {
        borrowerOperations.claimCollateral();
        _eventName = "LogClaimCollateralFromRedemption(address)";
        _eventParam = abi.encode(msg.sender);
    }
    /* End: Trove */

    /* Begin: Stability Pool */

    /**
     * @dev Deposit LUSD into Stability Pool
     * @notice Deposit LUSD into Stability Pool
     * @param amount Amount of LUSD to deposit into Stability Pool
     * @param frontendTag Address of the frontend to make this deposit against (determines the kickback rate of rewards)
     * @param getId Optional storage slot to retrieve the LUSD from
    */
    function stabilityDeposit(
        uint amount,
        address frontendTag,
        uint getId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        amount = getUint(getId, amount);

        stabilityPool.provideToSP(amount, frontendTag);
        
        _eventName = "LogStabilityDeposit(address,uint,address,uint)";
        _eventParam = abi.encode(msg.sender, amount, frontendTag, getId);
    }

    /**
     * @dev Withdraw user deposited LUSD from Stability Pool
     * @notice Withdraw LUSD from Stability Pool
     * @param amount Amount of LUSD to withdraw from Stability Pool
     * @param setId Optional storage slot to store the withdrawn LUSD
    */
    function stabilityWithdraw(
        uint amount,
        uint setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        stabilityPool.withdrawFromSP(amount);
        setUint(setId, amount);

        _eventName = "LogStabilityWithdraw(address,uint,uint)";
        _eventParam = abi.encode(msg.sender, amount, setId);
    }

    /**
     * @dev Increase Trove collateral by sending Stability Pool ETH gain to user's Trove
     * @notice Moves user's ETH gain from the Stability Pool into their Trove
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove will now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove will now sit in the ordered Trove list
    */
    function stabilityMoveEthGainToTrove(
        address upperHint,
        address lowerHint
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        stabilityPool.withdrawETHGainToTrove(upperHint, lowerHint);

        _eventName = "LogStabilityMoveEthGainToTrove(address)";
        _eventParam = abi.encode(msg.sender);
    }
    /* End: Stability Pool */

    /* Begin: Staking */

    /**
     * @dev Sends LQTY tokens from user to Staking Pool
     * @notice Stake LQTY in Staking Pool
     * @param amount Amount of LQTY to stake
     * @param getId Optional storage slot to retrieve the LQTY from
    */
    function stake(
        uint amount,
        uint getId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        amount = getUint(getId, amount);
        staking.stake(amount);
        _eventName = "LogStake(address,uint,uint)";
        _eventParam = abi.encode(msg.sender, amount, getId);
    }

    /**
     * @dev Sends LQTY tokens from Staking Pool to user
     * @notice Unstake LQTY in Staking Pool
     * @param amount Amount of LQTY to unstake
     * @param setId Optional storage slot to store the unstaked LQTY
    */
    function unstake(
        uint amount,
        uint setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        staking.unstake(amount);
        setUint(setId, amount);
        _eventName = "LogUnstake(address,uint,uint)";
        _eventParam = abi.encode(msg.sender, amount, setId);
    }

    /**
     * @dev Sends ETH and LUSD gains from Staking to user
     * @notice Claim ETH and LUSD gains from Staking
    */
    function claimGains() external returns (string memory _eventName, bytes memory _eventParam) {
        // claims are gained when a user's stake is adjusted, so we unstake 0 to trigger the claim
        staking.unstake(0); 
        _eventName = "LogClaimGains(address)";
        _eventParam = abi.encode(msg.sender);
    }
    /* End: Staking */

}

contract ConnectV2Liquity is LiquityResolver {
    string public name = "Liquity-v1";
}
