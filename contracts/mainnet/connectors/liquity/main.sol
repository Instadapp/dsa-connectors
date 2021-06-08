pragma solidity ^0.7.6;

/**
 * @title Liquity.
 * @dev Lending & Borrowing.
 */
import {
    BorrowerOperationsLike,
    TroveManagerLike,
    StabilityPoolLike,
    StakingLike,
    CollateralSurplusLike
} from "./interface.sol";
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
    CollateralSurplusLike internal constant collateralSurplus =
        CollateralSurplusLike(0x3D32e8b97Ed5881324241Cf03b2DA5E2EBcE5521);
    
    // Prevents stack-too-deep error
    struct AdjustTrove {
        uint maxFeePercentage;
        uint withdrawAmount;
        uint depositAmount;
        uint borrowAmount;
        uint repayAmount;
        bool isBorrow;
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
     * @param getId Optional storage slot to retrieve ETH from
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
        if (getId != 0 && depositAmount != 0) {
            revert("open(): Cannot supply a depositAmount if a non-zero getId is supplied");
        }

        depositAmount = getUint(getId, depositAmount);

        borrowerOperations.openTrove{value: depositAmount}(
            maxFeePercentage,
            borrowAmount,
            upperHint,
            lowerHint
        );

        // Allow other spells to use the borrowed amount
        setUint(setId, borrowAmount);
        _eventName = "LogOpen(address,uint256,uint256,uint256,uint256,uint256)";
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
         _eventName = "LogClose(address,uint256)";
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
        if (getId != 0 && amount != 0) {
            revert("deposit(): Cannot supply an amount if a non-zero getId is supplied");
        }
        amount = getUint(getId, amount);
        borrowerOperations.addColl{value: amount}(upperHint, lowerHint);
        _eventName = "LogDeposit(address,uint256,uint256)";
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
        _eventName = "LogWithdraw(address,uint256,uint256)";
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
        _eventName = "LogBorrow(address,uint256,uint256)";
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
        if (getId != 0 && amount != 0) {
            revert("repay(): Cannot supply an amount if a non-zero getId is supplied");
        }
        amount = getUint(getId, amount);
        borrowerOperations.repayLUSD(amount, upperHint, lowerHint);
        _eventName = "LogRepay(address,uint256,uint256)";
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
        if (getDepositId != 0 && depositAmount != 0) {
            revert("adjust(): Cannot supply a depositAmount if a non-zero getDepositId is supplied");
        }
        if (getRepayId != 0 && repayAmount != 0) {
            revert("adjust(): Cannot supply a repayAmount if a non-zero getRepayId is supplied");
        }
        AdjustTrove memory adjustTrove;

        adjustTrove.maxFeePercentage = maxFeePercentage;
        adjustTrove.withdrawAmount = withdrawAmount;
        adjustTrove.depositAmount = getUint(getDepositId, depositAmount);
        adjustTrove.borrowAmount = borrowAmount;
        adjustTrove.repayAmount = getUint(getRepayId, repayAmount);
        adjustTrove.isBorrow = borrowAmount > 0;

        borrowerOperations.adjustTrove{value: adjustTrove.depositAmount}(
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

        _eventName = "LogAdjust(address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(msg.sender, maxFeePercentage, depositAmount, withdrawAmount, borrowAmount, repayAmount, getDepositId, setWithdrawId, getRepayId, setBorrowId);
    }

    /**
     * @dev Withdraw remaining ETH balance from user's redeemed Trove to their DSA
     * @param setId Optional storage slot to store the ETH claimed
     * @notice Claim remaining collateral from Trove
    */
    function claimCollateralFromRedemption(uint setId) external returns(string memory _eventName, bytes memory _eventParam) {
        uint amount = collateralSurplus.getCollateral(address(this));
        borrowerOperations.claimCollateral();
        setUint(setId, amount);

        _eventName = "LogClaimCollateralFromRedemption(address,uint256,uint256)";
        _eventParam = abi.encode(msg.sender, amount, setId);
    }
    /* End: Trove */

    /* Begin: Stability Pool */

    /**
     * @dev Deposit LUSD into Stability Pool
     * @notice Deposit LUSD into Stability Pool
     * @param amount Amount of LUSD to deposit into Stability Pool
     * @param frontendTag Address of the frontend to make this deposit against (determines the kickback rate of rewards)
     * @param getDepositId Optional storage slot to retrieve the LUSD from
     * @param setEthGainId Optional storage slot to store any ETH gains in
     * @param setLqtyGainId Optional storage slot to store any ETH gains in
    */
    function stabilityDeposit(
        uint amount,
        address frontendTag,
        uint getDepositId,
        uint setEthGainId,
        uint setLqtyGainId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        amount = getUint(getDepositId, amount);

        uint ethGain = stabilityPool.getDepositorETHGain(address(this));
        uint lqtyGain = stabilityPool.getDepositorLQTYGain(address(this));
        
        stabilityPool.provideToSP(amount, frontendTag);
        setUint(setEthGainId, ethGain);
        setUint(setLqtyGainId, lqtyGain);

        _eventName = "LogStabilityDeposit(address,uint256,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(msg.sender, amount, frontendTag, getDepositId, setEthGainId, setLqtyGainId);
    }

    /**
     * @dev Withdraw user deposited LUSD from Stability Pool
     * @notice Withdraw LUSD from Stability Pool
     * @param amount Amount of LUSD to withdraw from Stability Pool
     * @param setWithdrawId Optional storage slot to store the withdrawn LUSD
     * @param setEthGainId Optional storage slot to store any ETH gains in
     * @param setLqtyGainId Optional storage slot to store any ETH gains in
    */
    function stabilityWithdraw(
        uint amount,
        uint setWithdrawId,
        uint setEthGainId,
        uint setLqtyGainId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        stabilityPool.withdrawFromSP(amount);
        uint ethGain = stabilityPool.getDepositorETHGain(address(this));
        uint lqtyGain = stabilityPool.getDepositorLQTYGain(address(this));
        
        setUint(setWithdrawId, amount);
        setUint(setEthGainId, ethGain);
        setUint(setLqtyGainId, lqtyGain);

        _eventName = "LogStabilityWithdraw(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(msg.sender, amount, setWithdrawId, setEthGainId, setLqtyGainId);
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
        uint amount = stabilityPool.getDepositorETHGain(address(this));
        stabilityPool.withdrawETHGainToTrove(upperHint, lowerHint);
        _eventName = "LogStabilityMoveEthGainToTrove(address,uint256)";
        _eventParam = abi.encode(msg.sender, amount);
    }
    /* End: Stability Pool */

    /* Begin: Staking */

    /**
     * @dev Sends LQTY tokens from user to Staking Pool
     * @notice Stake LQTY in Staking Pool
     * @param amount Amount of LQTY to stake
     * @param getStakeId Optional storage slot to retrieve the LQTY from
     * @param setEthGainId Optional storage slot to store any ETH gains
     * @param setLusdGainId Optional storage slot to store any LUSD gains
    */
    function stake(
        uint amount,
        uint getStakeId,
        uint setEthGainId,
        uint setLusdGainId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint ethGain = staking.getPendingETHGain(address(this));
        uint lusdGain = staking.getPendingLUSDGain(address(this));

        amount = getUint(getStakeId, amount);
        staking.stake(amount);
        setUint(setEthGainId, ethGain);
        setUint(setLusdGainId, lusdGain);

        _eventName = "LogStake(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(msg.sender, amount, getStakeId, setEthGainId, setLusdGainId);
    }

    /**
     * @dev Sends LQTY tokens from Staking Pool to user
     * @notice Unstake LQTY in Staking Pool
     * @param amount Amount of LQTY to unstake
     * @param setStakeId Optional storage slot to store the unstaked LQTY
     * @param setEthGainId Optional storage slot to store any ETH gains
     * @param setLusdGainId Optional storage slot to store any LUSD gains
    */
    function unstake(
        uint amount,
        uint setStakeId,
        uint setEthGainId,
        uint setLusdGainId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint ethGain = staking.getPendingETHGain(address(this));
        uint lusdGain = staking.getPendingLUSDGain(address(this));

        staking.unstake(amount);
        setUint(setStakeId, amount);
        setUint(setEthGainId, ethGain);
        setUint(setLusdGainId, lusdGain);

        _eventName = "LogUnstake(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(msg.sender, amount, setStakeId, setEthGainId, setLusdGainId);
    }

    /**
     * @dev Sends ETH and LUSD gains from Staking to user
     * @notice Claim ETH and LUSD gains from Staking
     * @param setEthGainId Optional storage slot to store the claimed ETH
     * @param setLusdGainId Optional storage slot to store the claimed LUSD
    */
    function claimStakingGains(
        uint setEthGainId,
        uint setLusdGainId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint ethGain = staking.getPendingETHGain(address(this));
        uint lusdGain = staking.getPendingLUSDGain(address(this));

        // Gains are claimed when a user's stake is adjusted, so we unstake 0 to trigger the claim
        staking.unstake(0);
        setUint(setEthGainId, ethGain);
        setUint(setLusdGainId, lusdGain);
        
        _eventName = "LogClaimStakingGains(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(msg.sender, ethGain, lusdGain, setEthGainId, setLusdGainId);
    }
    /* End: Staking */

}

contract ConnectV2Liquity is LiquityResolver {
    string public name = "Liquity-v1";
}
