pragma solidity ^0.7.6;
pragma abicoder v2;

import {Helpers} from "./helpers.sol";
import {SafeInt256} from "./SafeInt256.sol";
import {Events} from "./events.sol";
import {DepositActionType, BalanceActionWithTrades, BalanceAction} from "./interface.sol";
import {TokenInterface} from "../../common/interfaces.sol";

/**
 * @title Notional
 * @notice Fixed Rate Lending and Borrowing
 */
abstract contract NotionalResolver is Events, Helpers {
    using SafeInt256 for int256;

    /**
     * @notice Deposit collateral into Notional
     * @param currencyId notional defined currency id to deposit
     * @param useUnderlying if true, will accept a deposit in the underlying currency (i.e DAI), if false
     * will use the asset currency (i.e. cDAI)
     * @param depositAmount amount of tokens to deposit
     * @param getId id of depositAmount
     * @param setId id to set the value of notional cash deposit increase (denominated in asset cash, i.e. cDAI)
     */
    function depositCollateral(
        uint16 currencyId,
        bool useUnderlying,
        uint256 depositAmount,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        depositAmount = getDepositAmountAndSetApproval(
            getId,
            currencyId,
            useUnderlying,
            depositAmount
        );

        uint256 assetCashDeposited;
        if (useUnderlying && currencyId == ETH_CURRENCY_ID) {
            assetCashDeposited = notional.depositUnderlyingToken{
                value: depositAmount
            }(address(this), currencyId, depositAmount);
        } else if (useUnderlying) {
            assetCashDeposited = notional.depositUnderlyingToken(
                address(this),
                currencyId,
                depositAmount
            );
        } else {
            assetCashDeposited = notional.depositAssetToken(
                address(this),
                currencyId,
                depositAmount
            );
        }

        setUint(setId, assetCashDeposited);

        _eventName = "LogDepositCollateral(uint16,bool,uint256,uint256)";
        _eventParam = abi.encode(
            address(this),
            currencyId,
            useUnderlying,
            depositAmount,
            assetCashDeposited
        );
    }

    /**
     * @notice Withdraw collateral from Notional
     * @param currencyId notional defined currency id to withdraw
     * @param redeemToUnderlying if true, will redeem the amount withdrawn to the underlying currency (i.e. DAI),
     * if false, will simply withdraw the asset token (i.e. cDAI)
     * @param withdrawAmount amount of tokens to withdraw, denominated in asset tokens (i.e. cDAI)
     * @param getId id of withdraw amount
     * @param setId id to set the value of amount withdrawn, if redeemToUnderlying this amount will be in underlying
     * (i.e. DAI), if not redeemToUnderlying this amount will be asset tokens (i.e. cDAI)
     */
    function withdrawCollateral(
        uint16 currencyId,
        bool redeemToUnderlying,
        uint256 withdrawAmount,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        withdrawAmount = getUint(getId, withdrawAmount);
        uint88 amountInternalPrecision = withdrawAmount == uint256(-1)
            ? uint88(getCashBalance(currencyId))
            : uint88(convertToInternal(currencyId, int256(withdrawAmount)));

        uint256 amountWithdrawn = notional.withdraw(
            currencyId,
            amountInternalPrecision,
            redeemToUnderlying
        );
        // Sets the amount of tokens withdrawn to address(this)
        setUint(setId, amountWithdrawn);

        _eventName = "LogWithdrawCollateral(address,uint16,bool,uint256)";
        _eventParam = abi.encode(
            address(this),
            currencyId,
            redeemToUnderlying,
            amountWithdrawn
        );
    }

    /**
     * @dev Claims NOTE tokens and transfers to the address
     * @param setId the id to set the balance of NOTE tokens claimed
     */
    function claimNOTE(uint256 setId)
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 notesClaimed = notional.nTokenClaimIncentives();
        setUint(setId, notesClaimed);

        _eventName = "LogClaimNOTE(address,uint256)";
        _eventParam = abi.encode(address(this), notesClaimed);
    }

    /**
     * @notice Redeem nTokens allowing for accepting of fCash residuals
     * @dev This spell allows users to redeem nTokens even when there are fCash residuals that
     * cannot be sold when markets are at extremely high utilization
     * @param currencyId notional defined currency id of nToken
     * @param sellTokenAssets set to false to accept fCash residuals into portfolio, set to true will
     * sell fCash residuals back to cash
     * @param tokensToRedeem amount of nTokens to redeem
     * @param getId id of amount of tokens to redeem
     * @param setId id to set amount of asset cash from redeem
     */
    function redeemNTokenRaw(
        uint16 currencyId,
        bool sellTokenAssets,
        uint96 tokensToRedeem,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        tokensToRedeem = uint96(getUint(getId, tokensToRedeem));
        if (tokensToRedeem == uint96(-1))
            tokensToRedeem = uint96(getNTokenBalance(currencyId));
        int256 _assetCashChange = notional.nTokenRedeem(
            address(this),
            currencyId,
            tokensToRedeem,
            sellTokenAssets
        );

        // Floor asset cash change at zero in order to properly set the uint. If the asset cash change is negative
        // (this will almost certainly never happen), then no withdraw is possible.
        uint256 assetCashChange = _assetCashChange > 0
            ? uint256(_assetCashChange)
            : 0;

        setUint(setId, assetCashChange);

        _eventName = "LogRedeemNTokenRaw(address,uint16,bool,uint96,int256)";
        _eventParam = abi.encode(
            address(this),
            currencyId,
            sellTokenAssets,
            tokensToRedeem,
            assetCashChange
        );
    }

    /**
     * @notice Redeems nTokens to cash and withdraws the resulting cash
     * @dev Also possible to use redeemNTokenRaw and withdrawCollateral to achieve the same
     * result but this is more gas efficient, it does it in one call to Notional
     * @param currencyId notional defined currency id of nToken
     * @param tokensToRedeem amount of nTokens to redeem
     * @param amountToWithdraw amount of asset cash to withdraw, if set to uint(-1) then will withdraw the
     * entire cash balance in notional
     * @param redeemToUnderlying if true, will redeem the asset cash withdrawn to underlying tokens
     * @param getId id of amount of tokens to redeem
     * @param setId id to set amount of asset cash or underlying tokens withdrawn
     */
    function redeemNTokenAndWithdraw(
        uint16 currencyId,
        uint96 tokensToRedeem,
        uint256 amountToWithdraw,
        bool redeemToUnderlying,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        tokensToRedeem = uint96(getUint(getId, uint256(tokensToRedeem)));
        if (tokensToRedeem == uint96(-1))
            tokensToRedeem = uint96(getNTokenBalance(currencyId));

        BalanceAction[] memory action = new BalanceAction[](1);
        action[0].actionType = DepositActionType.RedeemNToken;
        action[0].currencyId = currencyId;
        action[0].depositActionAmount = tokensToRedeem;
        action[0].redeemToUnderlying = redeemToUnderlying;
        if (amountToWithdraw == uint256(-1)) {
            action[0].withdrawEntireCashBalance = true;
        } else {
            action[0].withdrawAmountInternalPrecision = amountToWithdraw;
        }

        executeActionWithBalanceChange(
            action,
            0,
            currencyId,
            redeemToUnderlying,
            setId
        );

        _eventName = "LogRedeemNTokenWithdraw(address,uint16,uint96,uint256,bool)";
        _eventParam = abi.encode(
            address(this),
            currencyId,
            tokensToRedeem,
            amountToWithdraw,
            redeemToUnderlying
        );
    }

    /**
     * @notice Redeems nTokens and uses the cash to repay a borrow.
     * @dev When specifying fCashAmount be sure to calculate it such that the account
     * has enough cash after redeeming nTokens to pay down the debt. This can be done
     * off-chain using the Notional SDK.
     * @param currencyId notional defined currency id of nToken
     * @param tokensToRedeem amount of nTokens to redeem
     * @param marketIndex the market index that references where the account will lend
     * @param fCashAmount amount of fCash to lend into the market, the corresponding amount of cash will
     * be taken from the account after redeeming nTokens
     * @param minLendRate minimum rate where the user will lend, if the rate is lower will revert
     * @param getId id of amount of tokens to redeem
     */
    function redeemNTokenAndDeleverage(
        uint16 currencyId,
        uint96 tokensToRedeem,
        uint8 marketIndex,
        uint88 fCashAmount,
        uint32 minLendRate,
        uint256 getId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        tokensToRedeem = uint96(getUint(getId, tokensToRedeem));
        if (tokensToRedeem == uint96(-1))
            tokensToRedeem = uint96(getNTokenBalance(currencyId));

        BalanceActionWithTrades[] memory action = new BalanceActionWithTrades[](
            1
        );
        action[0].actionType = DepositActionType.RedeemNToken;
        action[0].currencyId = currencyId;
        action[0].depositActionAmount = tokensToRedeem;
        // Withdraw amount, withdraw cash balance and redeemToUnderlying are all 0 or false

        bytes32[] memory trades = new bytes32[](1);
        trades[0] = encodeLendTrade(marketIndex, fCashAmount, minLendRate);
        action[0].trades = trades;

        notional.batchBalanceAndTradeAction(address(this), action);

        _eventName = "LogRedeemNTokenAndDeleverage(address,uint16,uint96,uint8,uint88)";
        _eventParam = abi.encode(
            address(this),
            currencyId,
            tokensToRedeem,
            marketIndex,
            fCashAmount
        );
    }

    /**
     * @notice Deposit asset or underlying tokens and mint nTokens in a single transaction
     * @param currencyId notional defined currency id to deposit
     * @param depositAmount amount of tokens to deposit
     * @param useUnderlying if true, will accept a deposit in the underlying currency (i.e DAI), if false
     * will use the asset currency (i.e. cDAI)
     * @param getId id of depositAmount
     * @param setId id to set the value of notional cash deposit increase (denominated in asset cash, i.e. cDAI)
     */
    function depositAndMintNToken(
        uint16 currencyId,
        uint256 depositAmount,
        bool useUnderlying,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        depositAmount = getDepositAmountAndSetApproval(
            getId,
            currencyId,
            useUnderlying,
            depositAmount
        );

        BalanceAction[] memory action = new BalanceAction[](1);
        action[0].actionType = useUnderlying
            ? DepositActionType.DepositUnderlyingAndMintNToken
            : DepositActionType.DepositAssetAndMintNToken;
        action[0].currencyId = currencyId;
        action[0].depositActionAmount = depositAmount;
        // withdraw amount, withdraw cash and redeem to underlying are all 0 and false

        int256 nTokenBefore = getNTokenBalance(currencyId);

        uint256 msgValue = 0;
        if (currencyId == ETH_CURRENCY_ID && useUnderlying)
            msgValue = depositAmount;

        notional.batchBalanceAction{value: msgValue}(address(this), action);

        int256 nTokenBalanceChange = getNTokenBalance(currencyId).sub(
            nTokenBefore
        );

        if (setId != 0) {
            // Set the amount of nTokens minted
            setUint(setId, uint256(nTokenBalanceChange));
        }

        _eventName = "LogDepositAndMintNToken(address,uint16,bool,uint256,int256)";
        _eventParam = abi.encode(
            address(this),
            currencyId,
            useUnderlying,
            depositAmount,
            nTokenBalanceChange
        );
    }

    function mintNTokenFromCash(
        uint16 currencyId,
        uint256 cashBalanceToMint,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        cashBalanceToMint = getUint(getId, cashBalanceToMint);
        if (cashBalanceToMint == uint256(-1))
            cashBalanceToMint = uint256(getCashBalance(currencyId));

        BalanceAction[] memory action = new BalanceAction[](1);
        action[0].actionType = DepositActionType.ConvertCashToNToken;
        action[0].currencyId = currencyId;
        action[0].depositActionAmount = cashBalanceToMint;
        // NOTE: withdraw amount, withdraw cash and redeem to underlying are all 0 and false

        int256 nTokenBefore = getNTokenBalance(currencyId);

        notional.batchBalanceAction(address(this), action);

        int256 nTokenBalanceChange = getNTokenBalance(currencyId).sub(
            nTokenBefore
        );

        if (setId != 0) {
            // Set the amount of nTokens minted
            setUint(setId, uint256(nTokenBalanceChange));
        }

        _eventName = "LogMintNTokenFromCash(address,uint16,uint256,int256)";
        _eventParam = abi.encode(
            address(this),
            currencyId,
            cashBalanceToMint,
            nTokenBalanceChange
        );
    }

    function depositAndLend(
        uint16 currencyId,
        uint256 depositAmount,
        bool useUnderlying,
        uint8 marketIndex,
        uint88 fCashAmount,
        uint32 minLendRate,
        uint256 getId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        depositAmount = getDepositAmountAndSetApproval(
            getId,
            currencyId,
            useUnderlying,
            depositAmount
        );

        BalanceActionWithTrades[] memory action = new BalanceActionWithTrades[](
            1
        );
        action[0].actionType = useUnderlying
            ? DepositActionType.DepositUnderlying
            : DepositActionType.DepositAsset;
        action[0].currencyId = currencyId;
        action[0].depositActionAmount = depositAmount;
        // Withdraw any residual cash from lending back to the token that was used
        action[0].withdrawEntireCashBalance = true;
        action[0].redeemToUnderlying = useUnderlying;

        bytes32[] memory trades = new bytes32[](1);
        trades[0] = encodeLendTrade(marketIndex, fCashAmount, minLendRate);
        action[0].trades = trades;

        uint256 msgValue = 0;
        if (currencyId == ETH_CURRENCY_ID && useUnderlying)
            msgValue = depositAmount;

        notional.batchBalanceAndTradeAction{value: msgValue}(
            address(this),
            action
        );

        _eventName = "LogDepositAndLend(address,uint16,bool,uint256,uint8,uint88,uint32)";
        _eventParam = abi.encode(
            address(this),
            currencyId,
            useUnderlying,
            depositAmount,
            marketIndex,
            fCashAmount,
            minLendRate
        );
    }

    function getDepositCollateralBorrowAndWithdrawActions(
        uint16 depositCurrencyId,
        bool useUnderlying,
        uint256 depositAmount,
        uint16 borrowCurrencyId,
        uint8 marketIndex,
        uint88 fCashAmount,
        uint32 maxBorrowRate,
        bool redeemToUnderlying
    ) internal returns (BalanceActionWithTrades[] memory action) {
        BalanceActionWithTrades[]
            memory actions = new BalanceActionWithTrades[](2);

        uint256 depositIndex;
        uint256 borrowIndex;
        if (depositCurrencyId < borrowCurrencyId) {
            depositIndex = 0;
            borrowIndex = 1;
        } else {
            depositIndex = 1;
            borrowIndex = 0;
        }

        actions[depositIndex].actionType = useUnderlying
            ? DepositActionType.DepositUnderlying
            : DepositActionType.DepositAsset;
        actions[depositIndex].currencyId = depositCurrencyId;
        actions[depositIndex].depositActionAmount = depositAmount;

        actions[borrowIndex].actionType = DepositActionType.None;
        actions[borrowIndex].currencyId = borrowCurrencyId;
        // Withdraw borrowed amount to wallet
        actions[borrowIndex].withdrawEntireCashBalance = true;
        actions[borrowIndex].redeemToUnderlying = redeemToUnderlying;

        bytes32[] memory trades = new bytes32[](1);
        trades[0] = encodeBorrowTrade(marketIndex, fCashAmount, maxBorrowRate);
        actions[borrowIndex].trades = trades;

        return actions;
    }

    function depositCollateralBorrowAndWithdraw(
        uint16 depositCurrencyId,
        bool useUnderlying,
        uint256 depositAmount,
        uint16 borrowCurrencyId,
        uint8 marketIndex,
        uint88 fCashAmount,
        uint32 maxBorrowRate,
        bool redeemToUnderlying,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        require(depositCurrencyId != borrowCurrencyId);

        depositAmount = getDepositAmountAndSetApproval(
            getId,
            depositCurrencyId,
            useUnderlying,
            depositAmount
        );

        BalanceActionWithTrades[]
            memory actions = getDepositCollateralBorrowAndWithdrawActions(
                depositCurrencyId,
                useUnderlying,
                depositAmount,
                borrowCurrencyId,
                marketIndex,
                fCashAmount,
                maxBorrowRate,
                redeemToUnderlying
            );

        uint256 msgValue = 0;
        if (depositCurrencyId == ETH_CURRENCY_ID && useUnderlying)
            msgValue = depositAmount;

        executeTradeActionWithBalanceChange(
            actions,
            msgValue,
            borrowCurrencyId,
            redeemToUnderlying,
            setId
        );

        _eventName = "LogDepositCollateralBorrowAndWithdraw(address,bool,uint256,uint16,uint8,uint88,uint32,bool)";
        _eventParam = abi.encode(
            address(this),
            useUnderlying,
            depositAmount,
            borrowCurrencyId,
            marketIndex,
            fCashAmount,
            maxBorrowRate,
            redeemToUnderlying
        );
    }

    function withdrawLend(
        uint16 currencyId,
        uint8 marketIndex,
        uint88 fCashAmount,
        uint32 maxBorrowRate,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        bool useUnderlying = currencyId != ETH_CURRENCY_ID;
        BalanceActionWithTrades[] memory action = new BalanceActionWithTrades[](
            1
        );
        action[0].actionType = DepositActionType.None;
        action[0].currencyId = currencyId;
        // Withdraw borrowed amount to wallet
        action[0].withdrawEntireCashBalance = true;
        action[0].redeemToUnderlying = useUnderlying;

        bytes32[] memory trades = new bytes32[](1);
        trades[0] = encodeBorrowTrade(marketIndex, fCashAmount, maxBorrowRate);
        action[0].trades = trades;

        executeTradeActionWithBalanceChange(
            action,
            0,
            currencyId,
            useUnderlying,
            setId
        );

        _eventName = "LogWithdrawLend(address,uint16,uint8,uint88,uint32)";
        _eventParam = abi.encode(
            address(this),
            currencyId,
            marketIndex,
            fCashAmount,
            maxBorrowRate
        );
    }

    function repayBorrow(
        uint16 currencyId,
        uint8 marketIndex,
        int88 netCashToAccount,
        uint32 minLendRate,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        int256 fCashAmount = notional.getfCashAmountGivenCashAmount(
            currencyId,
            int88(int256(netCashToAccount).neg()),
            marketIndex,
            block.timestamp
        );

        bool useUnderlying = currencyId != ETH_CURRENCY_ID;
        BalanceActionWithTrades[] memory action = new BalanceActionWithTrades[](
            1
        );
        action[0].actionType = DepositActionType.None;
        action[0].currencyId = currencyId;
        // Withdraw borrowed amount to wallet
        action[0].withdrawEntireCashBalance = true;
        action[0].redeemToUnderlying = useUnderlying;

        bytes32[] memory trades = new bytes32[](1);
        trades[0] = encodeLendTrade(
            marketIndex,
            uint88(fCashAmount),
            minLendRate
        );
        action[0].trades = trades;

        executeTradeActionWithBalanceChange(
            action,
            0,
            currencyId,
            useUnderlying,
            setId
        );

        _eventName = "LogRepayBorrow(address,uint16,uint8,uint88,uint32)";
        _eventParam = abi.encode(
            address(this),
            currencyId,
            marketIndex,
            netCashToAccount,
            minLendRate
        );
    }

    /**
     * @notice Executes a number of batch actions on the account without getId or setId integration
     * @dev This method will allow the user to take almost any action on Notional but does not have any
     * getId or setId integration. This can be used to roll lends and borrows forward.
     * @param actions a set of BatchActionWithTrades that will be executed for this account
     */
    function batchActionRaw(BalanceActionWithTrades[] memory actions)
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        notional.batchBalanceAndTradeAction(address(this), actions);

        _eventName = "LogBatchActionRaw(address)";
        _eventParam = abi.encode(address(this));
    }
}

contract ConnectV2Notional is NotionalResolver {
    string public name = "Notional-v1.1";
}
