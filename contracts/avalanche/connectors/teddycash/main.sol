pragma solidity ^0.7.6;

/**
 * @title TeddyCash.
 * @dev Lending & Borrowing.
 */
import {
    BorrowerOperationsLike,
    TroveManagerLike,
    StabilityPoolLike,
    StakingLike,
    CollateralSurplusLike,
    TeddyTokenLike
} from "./interface.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract TeddyCashResolver is Events, Helpers {


    /* Begin: Trove */

    /**
     * @dev Deposit native AVAX and borrow TSD
     * @notice Opens a Trove by depositing AVAX and borrowing TSD
     * @param depositAmount The amount of AVAX to deposit
     * @param maxFeePercentage The maximum borrow fee that this transaction should permit 
     * @param borrowAmount The amount of TSD to borrow
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove should now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove should now sit in the ordered Trove list
     * @param getIds Optional (default: 0) Optional storage slot to get deposit & borrow amounts stored using other spells
     * @param setIds Optional (default: 0) Optional storage slot to set deposit & borrow amounts to be used in future spells
    */
    function open(
        uint depositAmount,
        uint maxFeePercentage,
        uint borrowAmount,
        address upperHint,
        address lowerHint,
        uint[] memory getIds,
        uint[] memory setIds
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {

        depositAmount = getUint(getIds[0], depositAmount);
        borrowAmount = getUint(getIds[1], borrowAmount);

        depositAmount = depositAmount == uint(-1) ? address(this).balance : depositAmount;

        borrowerOperations.openTrove{value: depositAmount}(
            maxFeePercentage,
            borrowAmount,
            upperHint,
            lowerHint
        );

        setUint(setIds[0], depositAmount);
        setUint(setIds[1], borrowAmount);

        _eventName = "LogOpen(address,uint256,uint256,uint256,uint256[],uint256[])";
        _eventParam = abi.encode(address(this), maxFeePercentage, depositAmount, borrowAmount, getIds, setIds);
    }

    /**
     * @dev Repay TSD debt from the DSA account's TSD balance, and withdraw AVAX to DSA
     * @notice Closes a Trove by repaying TSD debt
     * @param setId Optional storage slot to store the AVAX withdrawn from the Trove
    */
    function close(uint setId) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint collateral = troveManager.getTroveColl(address(this));
        borrowerOperations.closeTrove();

        // Allow other spells to use the collateral released from the Trove
        setUint(setId, collateral);
         _eventName = "LogClose(address,uint256)";
        _eventParam = abi.encode(address(this), setId);
    }

    /**
     * @dev Deposit AVAX to Trove
     * @notice Increase Trove collateral (collateral Top up)
     * @param amount Amount of AVAX to deposit into Trove
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove should now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove should now sit in the ordered Trove list
     * @param getId Optional storage slot to retrieve the AVAX from
     * @param setId Optional storage slot to set the AVAX deposited
    */
    function deposit(
        uint amount,
        address upperHint,
        address lowerHint,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam)  {

        uint _amount = getUint(getId, amount);

        _amount = _amount == uint(-1) ? address(this).balance : _amount;

        borrowerOperations.addColl{value: _amount}(upperHint, lowerHint);

        setUint(setId, _amount);

        _eventName = "LogDeposit(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), _amount, getId, setId);
    }

    /**
     * @dev Withdraw AVAX from Trove
     * @notice Move Trove collateral from Trove to DSA
     * @param amount Amount of AVAX to move from Trove to DSA
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove should now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove should now sit in the ordered Trove list
     * @param getId Optional storage slot to get the amount of AVAX to withdraw
     * @param setId Optional storage slot to store the withdrawn AVAX in
    */
   function withdraw(
        uint amount,
        address upperHint,
        address lowerHint,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam)  {
        uint _amount = getUint(getId, amount);

        _amount = _amount == uint(-1) ? troveManager.getTroveColl(address(this)) : _amount;

        borrowerOperations.withdrawColl(_amount, upperHint, lowerHint);

        setUint(setId, _amount);
        _eventName = "LogWithdraw(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), _amount, getId, setId);
    }
    
    /**
     * @dev Mints TSD tokens
     * @notice Borrow TSD via an existing Trove
     * @param maxFeePercentage The maximum borrow fee that this transaction should permit 
     * @param amount Amount of TSD to borrow
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove should now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove should now sit in the ordered Trove list
     * @param getId Optional storage slot to retrieve the amount of TSD to borrow
     * @param setId Optional storage slot to store the final amount of TSD borrowed
    */
    function borrow(
        uint maxFeePercentage,
        uint amount,
        address upperHint,
        address lowerHint,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam)  {
        uint _amount = getUint(getId, amount);

        borrowerOperations.withdrawLUSD(maxFeePercentage, _amount, upperHint, lowerHint);

        setUint(setId, _amount);

        _eventName = "LogBorrow(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), _amount, getId, setId);
    }

    /**
     * @dev Send TSD to repay debt
     * @notice Repay TSD Trove debt
     * @param amount Amount of TSD to repay
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove should now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove should now sit in the ordered Trove list
     * @param getId Optional storage slot to retrieve the amount of TSD from
     * @param setId Optional storage slot to store the final amount of TSD repaid
    */
    function repay(
        uint amount,
        address upperHint,
        address lowerHint,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam)  {
        uint _amount = getUint(getId, amount);

        if (_amount == uint(-1)) {
            uint _tsdBal = tsdToken.balanceOf(address(this));
            uint _totalDebt = troveManager.getTroveDebt(address(this));
            _amount = _tsdBal > _totalDebt ? _totalDebt : _tsdBal;
        }

        borrowerOperations.repayLUSD(_amount, upperHint, lowerHint);

        setUint(setId, _amount);

        _eventName = "LogRepay(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), _amount, getId, setId);
    }

    /**
     * @dev Increase or decrease Trove AVAX collateral and TSD debt in one transaction
     * @notice Adjust Trove debt and/or collateral
     * @param maxFeePercentage The maximum borrow fee that this transaction should permit 
     * @param withdrawAmount Amount of AVAX to withdraw
     * @param depositAmount Amount of AVAX to deposit
     * @param borrowAmount Amount of TSD to borrow
     * @param repayAmount Amount of TSD to repay
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove should now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove should now sit in the ordered Trove list
     * @param getIds Optional Get Ids for deposit, withdraw, borrow & repay
     * @param setIds Optional Set Ids for deposit, withdraw, borrow & repay
    */
    function adjust(
        uint maxFeePercentage,
        uint depositAmount,
        uint withdrawAmount,
        uint borrowAmount,
        uint repayAmount,
        address upperHint,
        address lowerHint,
        uint[] memory getIds,
        uint[] memory setIds
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        AdjustTrove memory adjustTrove;

        adjustTrove.maxFeePercentage = maxFeePercentage;

        depositAmount = getUint(getIds[0], depositAmount);
        adjustTrove.depositAmount = depositAmount == uint(-1) ? address(this).balance : depositAmount;

        withdrawAmount = getUint(getIds[1], withdrawAmount);
        adjustTrove.withdrawAmount = withdrawAmount == uint(-1) ? troveManager.getTroveColl(address(this)) : withdrawAmount;

        borrowAmount = getUint(getIds[2], borrowAmount);

        repayAmount = getUint(getIds[3], repayAmount);
        if (repayAmount == uint(-1)) {
            uint _tsdBal = tsdToken.balanceOf(address(this));
            uint _totalDebt = troveManager.getTroveDebt(address(this));
            repayAmount = _tsdBal > _totalDebt ? _totalDebt : _tsdBal;
        }

        adjustTrove.isBorrow = borrowAmount > 0;
        adjustTrove.lusdChange = adjustTrove.isBorrow ? borrowAmount : repayAmount;
        
        borrowerOperations.adjustTrove{value: adjustTrove.depositAmount}(
            adjustTrove.maxFeePercentage,
            adjustTrove.withdrawAmount,
            adjustTrove.lusdChange,
            adjustTrove.isBorrow,
            upperHint,
            lowerHint
        );
        
        setUint(setIds[0], adjustTrove.depositAmount);
        setUint(setIds[1], adjustTrove.withdrawAmount);
        setUint(setIds[2], borrowAmount);
        setUint(setIds[3], repayAmount);

        _eventName = "LogAdjust(address,uint256,uint256,uint256,uint256,uint256,uint256[],uint256[])";
        _eventParam = abi.encode(address(this), maxFeePercentage, adjustTrove.depositAmount, adjustTrove.withdrawAmount, borrowAmount, repayAmount, getIds, setIds);
    }

    /**
     * @dev Withdraw remaining AVAX balance from user's redeemed Trove to their DSA
     * @param setId Optional storage slot to store the AVAX claimed
     * @notice Claim remaining collateral from Trove
    */
    function claimCollateralFromRedemption(uint setId) external payable returns(string memory _eventName, bytes memory _eventParam) {
        uint amount = collateralSurplus.getCollateral(address(this));
        borrowerOperations.claimCollateral();
        setUint(setId, amount);

        _eventName = "LogClaimCollateralFromRedemption(address,uint256,uint256)";
        _eventParam = abi.encode(address(this), amount, setId);
    }
    /* End: Trove */

    /* Begin: Stability Pool */

    /**
     * @dev Deposit TSD into Stability Pool
     * @notice Deposit TSD into Stability Pool
     * @param amount Amount of TSD to deposit into Stability Pool
     * @param frontendTag Address of the frontend to make this deposit against (determines the kickback rate of rewards)
     * @param getDepositId Optional storage slot to retrieve the amount of TSD from
     * @param setDepositId Optional storage slot to store the final amount of TSD deposited
     * @param setAvaxGainId Optional storage slot to store any AVAX gains in
     * @param setTeddyGainId Optional storage slot to store any TEDDY gains in
    */
    function stabilityDeposit(
        uint amount,
        address frontendTag,
        uint getDepositId,
        uint setDepositId,
        uint setAvaxGainId,
        uint setTeddyGainId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        amount = getUint(getDepositId, amount);

        amount = amount == uint(-1) ? tsdToken.balanceOf(address(this)) : amount;
 
        uint ethGain = stabilityPool.getDepositorETHGain(address(this));
        uint teddyBalanceBefore = teddyToken.balanceOf(address(this));
        
        stabilityPool.provideToSP(amount, frontendTag);
        
        uint teddyBalanceAfter = teddyToken.balanceOf(address(this));
        uint teddyGain = sub(teddyBalanceAfter, teddyBalanceBefore);

        setUint(setDepositId, amount);
        setUint(setAvaxGainId, ethGain);
        setUint(setTeddyGainId, teddyGain);

        _eventName = "LogStabilityDeposit(address,uint256,uint256,uint256,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), amount, ethGain, teddyGain, frontendTag, getDepositId, setDepositId, setAvaxGainId, setTeddyGainId);
    }

    /**
     * @dev Withdraw user deposited TSD from Stability Pool
     * @notice Withdraw TSD from Stability Pool
     * @param amount Amount of TSD to withdraw from Stability Pool
     * @param getWithdrawId Optional storage slot to retrieve the amount of TSD to withdraw from
     * @param setWithdrawId Optional storage slot to store the withdrawn TSD
     * @param setAvaxGainId Optional storage slot to store any AVAX gains in
     * @param setTeddyGainId Optional storage slot to store any TEDDY gains in
    */
    function stabilityWithdraw(
        uint amount,
        uint getWithdrawId,
        uint setWithdrawId,
        uint setAvaxGainId,
        uint setTeddyGainId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        amount = getUint(getWithdrawId, amount);

        amount = amount == uint(-1) ? stabilityPool.getCompoundedLUSDDeposit(address(this)) : amount;

        uint ethGain = stabilityPool.getDepositorETHGain(address(this));
        uint teddyBalanceBefore = teddyToken.balanceOf(address(this));
        
        stabilityPool.withdrawFromSP(amount);
        
        uint teddyBalanceAfter = teddyToken.balanceOf(address(this));
        uint teddyGain = sub(teddyBalanceAfter, teddyBalanceBefore);

        setUint(setWithdrawId, amount);
        setUint(setAvaxGainId, ethGain);
        setUint(setTeddyGainId, teddyGain);

        _eventName = "LogStabilityWithdraw(address,uint256,uint256,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), amount, ethGain, teddyGain, getWithdrawId, setWithdrawId, setAvaxGainId, setTeddyGainId);
    }

    /**
     * @dev Increase Trove collateral by sending Stability Pool AVAX gain to user's Trove
     * @notice Moves user's AVAX gain from the Stability Pool into their Trove
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove should now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove should now sit in the ordered Trove list
    */
    function stabilityMoveEthGainToTrove(
        address upperHint,
        address lowerHint
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint amount = stabilityPool.getDepositorETHGain(address(this));
        stabilityPool.withdrawETHGainToTrove(upperHint, lowerHint);
        _eventName = "LogStabilityMoveEthGainToTrove(address,uint256)";
        _eventParam = abi.encode(address(this), amount);
    }
    /* End: Stability Pool */

    /* Begin: Staking */

    /**
     * @dev Sends TEDDY tokens from user to Staking Pool
     * @notice Stake TEDDY in Staking Pool
     * @param amount Amount of TEDDY to stake
     * @param getStakeId Optional storage slot to retrieve the amount of TEDDY to stake
     * @param setStakeId Optional storage slot to store the final staked amount (can differ if requested with max balance: uint(-1))
     * @param setAvaxGainId Optional storage slot to store any AVAX gains
     * @param setTsdGainId Optional storage slot to store any TSD gains
    */
    function stake(
        uint amount,
        uint getStakeId,
        uint setStakeId,
        uint setAvaxGainId,
        uint setTsdGainId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        amount = getUint(getStakeId, amount);
        amount = amount == uint(-1) ? teddyToken.balanceOf(address(this)) : amount;

        uint ethGain = staking.getPendingETHGain(address(this));
        uint tsdGain = staking.getPendingLUSDGain(address(this));

        staking.stake(amount);
        setUint(setStakeId, amount);
        setUint(setAvaxGainId, ethGain);
        setUint(setTsdGainId, tsdGain);

        _eventName = "LogStake(address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), amount, getStakeId, setStakeId, setAvaxGainId, setTsdGainId);
    }

    /**
     * @dev Sends TEDDY tokens from Staking Pool to user
     * @notice Unstake TEDDY in Staking Pool
     * @param amount Amount of TEDDY to unstake
     * @param getUnstakeId Optional storage slot to retrieve the amount of TEDDY to unstake
     * @param setUnstakeId Optional storage slot to store the unstaked TEDDY
     * @param setAvaxGainId Optional storage slot to store any AVAX gains
     * @param setTsdGainId Optional storage slot to store any TSD gains
    */
    function unstake(
        uint amount,
        uint getUnstakeId,
        uint setUnstakeId,
        uint setAvaxGainId,
        uint setTsdGainId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        amount = getUint(getUnstakeId, amount);
        amount = amount == uint(-1) ? staking.stakes(address(this)) : amount;

        uint avaxGain = staking.getPendingETHGain(address(this));
        uint tsdGain = staking.getPendingLUSDGain(address(this));

        staking.unstake(amount);
        setUint(setUnstakeId, amount);
        setUint(setAvaxGainId, avaxGain);
        setUint(setTsdGainId, tsdGain);

        _eventName = "LogUnstake(address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), amount, getUnstakeId, setUnstakeId, setAvaxGainId, setTsdGainId);
    }

    /**
     * @dev Sends AVAX and TSD gains from Staking to user
     * @notice Claim AVAX and TSD gains from Staking
     * @param setAvaxGainId Optional storage slot to store the claimed AVAX
     * @param setTsdGainId Optional storage slot to store the claimed TSD
    */
    function claimStakingGains(
        uint setAvaxGainId,
        uint setTsdGainId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint avaxGain = staking.getPendingETHGain(address(this));
        uint tsdGain = staking.getPendingLUSDGain(address(this));

        // Gains are claimed when a user's stake is adjusted, so we unstake 0 to trigger the claim
        staking.unstake(0);
        setUint(setAvaxGainId, avaxGain);
        setUint(setTsdGainId, tsdGain);
        
        _eventName = "LogClaimStakingGains(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), avaxGain, tsdGain, setAvaxGainId, setTsdGainId);
    }
    /* End: Staking */

}

contract ConnectV2TeddyCash is TeddyCashResolver {
    string public name = "TeddyCash-v1";
}
