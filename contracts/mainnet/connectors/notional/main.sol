pragma solidity ^0.7.6;
pragma abicoder v2;

import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { DepositActionType, BalanceActionWithTrades, BalanceAction } from "./interface.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Notional
 * @notice Fixed Rate Lending and Borrowing
 */
abstract contract NotionalResolver is Events, Helpers {

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
        uint depositAmount,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint assetCashDeposited;
        address tokenAddress = useUnderlying ? getUnderlyingToken(currencyId) : getAssetToken(currencyId);
        depositAmount = getUint(getId, depositAmount);
        if (depositAmount == uint(-1)) depositAmount = IERC20(tokenAddress).balanceOf(address(this));

        approve(tokenAddress, address(notional), depositAmount);

        if (useUnderlying && currencyId == ETH_CURRENCY_ID) {
            assetCashDeposited = notional.depositUnderlyingToken{value: depositAmount}(address(this), currencyId, depositAmount);
        } else if (useUnderlying) {
            assetCashDeposited = notional.depositUnderlyingToken{value: depositAmount}(address(this), currencyId, depositAmount);
        } else {
            assetCashDeposited = notional.depositAssetToken(address(this), currencyId, depositAmount);
        }

        setUint(setId, assetCashDeposited);

        _eventName = "LogDepositCollateral(uint16,bool,uint256,uint256)";
        _eventParam = abi.encode(address(this), currencyId, useUnderlying, depositAmount, assetCashDeposited);
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
        uint withdrawAmount,
        uint getId,
        uint setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        withdrawAmount = getUint(getId, withdrawAmount);
        uint amountInternalPrecision = withdrawAmount == uint(-1) ?
            getCashBalance(currencyId) :
            convertToInternal(currencyId, withdrawAmount);

        uint amountWithdrawn = notional.withdraw(currencyId, amountInternalPrecision, redeemToUnderlying);
        // Sets the amount of tokens withdrawn to address(this)
        setUint(setId, amountWithdrawn);

        _eventName = "LogWithdrawCollateral(address,uint16,bool,uint256)";
        _eventParam = abi.encode(address(this), currencyId, redeemToUnderlying, amountWithdrawn);
    }

    /**
     * @dev Claims NOTE tokens and transfers to the address
     * @param setId the id to set the balance of NOTE tokens claimed
     */
    function claimNOTE(
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint notesClaimed = notional.nTokenClaimIncentives();
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
        uint tokensToRedeem,
        uint getId,
        uint setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        tokensToRedeem = getUint(getId, tokensToRedeem);
        if (tokensToRedeem == uint(-1)) tokensToRedeem = getNTokenBalance(currencyId);
        int _assetCashChange = notional.nTokenRedeem(address(this), currencyId, tokensToRedeem, sellTokenAssets);

        // Floor asset cash change at zero in order to properly set the uint. If the asset cash change is negative
        // (this will almost certainly never happen), then no withdraw is possible.
        uint assetCashChange = _assetCashChange > 0 ? uint(_assetCashChange) : 0;

        setUint(setId, assetCashChange);

        _eventName = "LogRedeemNTokenRaw(address,uint16,bool,uint,uint)";
        _eventParam = abi.encode(address(this), currencyId, sellTokenAssets, tokensToRedeem, assetCashChange);
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
        uint tokensToRedeem,
        uint amountToWithdraw,
        bool redeemToUnderlying,
        uint getId,
        uint setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        tokensToRedeem = getUint(getId, tokensToRedeem);
        if (tokensToRedeem == uint(-1)) tokensToRedeem = getNTokenBalance(currencyId);

        BalanceAction[] memory action = new BalanceAction[1];
        action[0].actionType = DepositActionType.RedeemNToken;
        action[0].currencyId = currencyId;
        action[0].depositActionAmount = tokensToRedeem;
        action[0].redeemToUnderlying = redeemToUnderlying;
        if (amountToWithdraw == uint(-1)) {
            action[0].withdrawEntireCashBalance = true;
        } else {
            action[0].withdrawAmountInternalPrecision = amountToWithdraw;
        }

        uint balanceBefore;
        address tokenAddress;
        if (setId != 0) {
            // Only run this if we are going to use the balance change
            address tokenAddress = redeemToUnderlying ? 
                getUnderlyingToken(currencyId) :
                getAssetToken(currencyId);
            
            // TODO: handle ETH
            balanceBefore = IERC20(tokenAddress).balanceOf(address(this));
        }

        notional.batchBalanceAction(address(this), action);

        if (setId != 0) {
            // TODO: handle ETH
            uint netBalance = sub(balanceBefore, IERC20(tokenAddress).balanceOf(address(this)));
            // This can be used to determine the exact amount withdrawn
            setUint(setId, netBalance);
        }

        _eventName = "LogRedeemNTokenWithdraw(address,uint16,uint,uint,bool)";
        _eventParam = abi.encode(address(this), currencyId, tokensToRedeem, amountToWithdraw, redeemToUnderlying);
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
        uint tokensToRedeem,
        uint8 marketIndex,
        uint fCashAmount,
        uint32 minLendRate,
        uint getId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        tokensToRedeem = getUint(getId, tokensToRedeem);
        if (tokensToRedeem == uint(-1)) tokensToRedeem = getNTokenBalance(currencyId);
        notional.nTokenRedeem(currencyId, tokensToRedeem, true);

        BalanceActionWithTrades[] memory action = new BalanceActionWithTrades[1];
        action[0].actionType = DepositActionType.RedeemNToken;
        action[0].currencyId = currencyId;
        action[0].depositActionAmount = tokensToRedeem;
        // Withdraw amount, withdraw cash balance and redeemToUnderlying are all 0 or false

        bytes32[] memory trades = new bytes32[](1);
        trades[0] = encodeLendTrade(marketIndex, fCashAmount, minLendRate);
        action[0].trades = trades;

        notional.batchBalanceAndTradeAction(address(this), action);

        _eventName = "LogRedeemNTokenAndDeleverage(address,uint16,uint,uint8,uint)";
        _eventParam = abi.encode(address(this), currencyId, tokensToRedeem, marketIndex, fCashAmount);
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
        uint depositAmount,
        bool useUnderlying,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        address tokenAddress = useUnderlying ? getUnderlyingToken(currencyId) : getAssetToken(currencyId);
        depositAmount = getUint(getId, depositAmount);
        if (depositAmount == uint(-1)) depositAmount = IERC20(tokenAddress).balanceOf(address(this));

        approve(tokenAddress, address(notional), depositAmount);
        BalanceAction[] memory action = new BalanceAction[1];
        action[0].actionType = useUnderlying ? DepositActionType.DepositUnderlyingAndMintNToken : DepositActionType.DepositAssetAndMintNToken;
        action[0].currencyId = currencyId;
        action[0].depositActionAmount = depositAmount;
        // withdraw amount, withdraw cash and redeem to underlying are all 0 and false

        uint nTokenBefore;
        if (setId != 0) {
            nTokenBefore = getNTokenBalance(currencyId);
        }

        uint msgValue = currencyId == ETH_CURRENCY_ID ? depositAmount : 0;
        notional.batchBalanceAndTradeAction{value: msgValue}(address(this), action);

        if (setId != 0) {
            // Set the amount of nTokens minted
            setUint(setId, sub(getNTokenBalance(currencyId), nTokenBefore));
        }

        // todo: events
    }

    function mintNTokenFromCash(
        uint16 currencyId,
        uint cashBalanceToMint,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        cashBalanceToMint = getUint(getId, cashBalanceToMint);
        if (cashBalanceToMint == uint(-1)) cashBalanceToMint = getCashBalance(currencyId);

        BalanceAction[] memory action = new BalanceAction[1];
        action[0].actionType = DepositActionType.ConvertCashToNToken;
        action[0].currencyId = currencyId;
        action[0].depositActionAmount = cashBalanceToMint;
        // NOTE: withdraw amount, withdraw cash and redeem to underlying are all 0 and false

        uint nTokenBefore;
        if (setId != 0) {
            nTokenBefore = getNTokenBalance(currencyId);
        }

        notional.batchBalanceActionWithTrades(address(this), action);

        if (setId != 0) {
            // Set the amount of nTokens minted
            setUint(setId, getNTokenBalance(currencyId).sub(nTokenBefore));
        }

        // todo: events
    }

    function depositAndLend(
        uint16 currencyId,
        uint depositAmount,
        bool useUnderlying,
        uint8 marketIndex,
        uint fCashAmount,
        uint minLendRate,
        uint getId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        address tokenAddress = useUnderlying ? getUnderlyingToken(currencyId) : getAssetToken(currencyId);
        depositAmount = getUint(getId, depositAmount);
        if (depositAmount == uint(-1)) depositAmount = IERC20(tokenAddress).balanceOf(address(this));

        approve(tokenAddress, address(notional), depositAmount);
        BalanceAction[] memory action = new BalanceAction[1];
        action[0].actionType = useUnderlying ? DepositActionType.DepositUnderlying : DepositActionType.DepositAsset;
        action[0].currencyId = currencyId;
        action[0].depositActionAmount = depositAmount;
        // Withdraw any residual cash from lending back to the token that was used
        action[0].withdrawEntireCashBalance = true;
        // TODO: will redeem underlying work with ETH?
        action[0].redeemToUnderlying = useUnderlying;

        bytes32[] memory trades = new bytes32[](1);
        trades[0] = encodeLendTrade(marketIndex, fCashAmount, minLendRate);
        action[0].trades = trades;

        uint msgValue = currencyId == ETH_CURRENCY_ID ? depositAmount : 0;
        notional.batchBalanceActionWithTrades{value: msgValue}(address(this), action);

        // todo: events
    }

    function depositCollateralBorrowAndWithdraw(
        uint16 depositCurrencyId,
        bool useUnderlying,
        uint depositAmount,
        uint16 borrowCurrencyId,
        uint8 marketIndex,
        uint fCashAmount,
        uint maxBorrowRate,
        bool redeemToUnderlying,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(depositCurrencyId != borrowCurrencyId);
        address tokenAddress = useUnderlying ? getUnderlyingToken(depositCurrencyId) : getAssetToken(depositCurrencyId);
        depositAmount = getUint(getId, depositAmount);
        if (depositAmount == uint(-1)) depositAmount = IERC20(tokenAddress).balanceOf(address(this));

        approve(tokenAddress, address(notional), depositAmount);
        BalanceActionWithTrades[] memory action = new BalanceActionWithTrades[](2);

        uint256 depositIndex;
        uint256 borrowIndex;
        if (depositCurrencyId < borrowCurrencyId) {
            depositIndex = 0;
            borrowIndex = 1;
        } else {
            depositIndex = 1;
            borrowIndex = 0;
        }

        action[depositIndex].actionType = useUnderlying ? DepositActionType.DepositUnderlying : DepositActionType.DepositAsset;
        action[depositIndex].currencyId = depositCurrencyId;
        action[depositIndex].depositActionAmount = depositAmount;
        uint msgValue = depositCurrencyId == ETH_CURRENCY_ID ? depositAmount : 0;

        action[borrowIndex].actionType = DepositActionType.None;
        action[borrowIndex].currencyId = borrowCurrencyId;
        // Withdraw borrowed amount to wallet
        action[borrowIndex].withdrawEntireCashBalance = true;
        // TODO: will redeem underlying work with ETH?
        action[borrowIndex].redeemToUnderlying = useUnderlying;

        bytes32[] memory trades = new bytes32[](1);
        trades[borrowIndex] = encodeBorrowTrade(marketIndex, fCashAmount, maxBorrowRate);
        action[borrowIndex].trades = trades;

        address borrowToken;
        uint balanceBefore;
        if (setId != 0) {
            address borrowToken = useUnderlying ? getUnderlyingToken(borrowCurrencyId) : getAssetToken(borrowCurrencyId);
            balanceBefore = IERC20(borrowToken).balanceOf(address(this));
        }

        notional.batchBalanceActionWithTrades{value: msgValue}(address(this), action);

        if (setId != 0) {
            setUint(setId, IERC20(borrowToken).balanceOf(address(this)).sub(balanceBefore));
        }

        // todo: events
    }

    function withdrawLend(
        uint16 currencyId,
        uint8 marketIndex,
        uint fCashAmount,
        uint maxBorrowRate,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        bool useUnderlying = currencyId != ETH_CURRENCY_ID;
        BalanceActionWithTrades[] memory action = new BalanceActionWithTrades[]();
        action[0].actionType = DepositActionType.None;
        action[0].currencyId = currencyId;
        // Withdraw borrowed amount to wallet
        action[0].withdrawEntireCashBalance = true;
        // TODO: will redeem underlying work with ETH?
        action[0].redeemToUnderlying = useUnderlying;

        bytes32[] memory trades = new bytes32[](1);
        trades[0] = encodeBorrowTrade(marketIndex, fCashAmount, maxBorrowRate);
        action[0].trades = trades;

        address tokenAddress;
        uint balanceBefore;
        if (setId != 0) {
            address tokenAddress = useUnderlying ? getUnderlyingToken(currencyId) : getAssetToken(currencyId);
            balanceBefore = IERC20(tokenAddress).balanceOf(address(this));
        }

        notional.batchBalanceActionWithTrades{value: msg.value}(address(this), action);

        if (setId != 0) {
            setUint(setId, IERC20(tokenAddress).balanceOf(address(this)).sub(balanceBefore));
        }
    }

    function repayBorrow(
        uint16 currencyId,
        uint8 marketIndex,
        uint fCashAmount,
        uint minLendRate,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        // might want to use getfCashAmountGivenCashAmount
    }

    /**
     * @notice Executes a number of batch actions on the account without getId or setId integration
     * @dev This method will allow the user to take almost any action on Notional but does not have any
     * getId or setId integration. This can be used to roll lends and borrows forward.
     * @param actions a set of BatchActionWithTrades that will be executed for this account
     */
    function batchActionRaw(
        BalanceActionWithTrades[] memory actions
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        notional.batchBalanceAndTradeAction(address(this), actions);

        // todo: events
    }
}