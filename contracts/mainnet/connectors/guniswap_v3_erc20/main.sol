pragma solidity ^0.7.0;

/**
 * @title G-Uniswap V3 ERC20 Wrapper.
 * @dev G-Uniswap V3 Wrapper to deposit and withdraw.
 */

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { TokenInterface } from "../../common/interfaces.sol";
import { IGUniPool, IERC20 } from "./interface.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract UniswapV3Resolver is Events, Helpers {
    using SafeERC20 for IERC20;

    /**
     * @dev Deposit Liquidity.
     * @notice Deposit Liquidity to Gelato Uniswap V3 pool.
     * @param pool The address of pool.
     * @param amt0Max Amount0 Max amount
     * @param amt1Max Amount1 Max amount
     * @param slippage use to calculate minimum deposit. 100% = 1e18
     * @param getIds Array of IDs to retrieve amounts.
     * @param setId ID stores the amount of pools tokens received.
    */
    function deposit(
        address pool,
        uint256 amt0Max,
        uint256 amt1Max,
        uint slippage,
        uint256[] calldata getIds,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {

        amt0Max = getUint(getIds[0], amt0Max);
        amt1Max = getUint(getIds[1], amt1Max);

        Deposit memory depositData;
        depositData.poolContract = IGUniPool(pool);

        (depositData.amount0In, depositData.amount1In, depositData.mintAmount) =
            depositData.poolContract.getMintAmounts(amt0Max, amt1Max);

        uint amt0Min = wmul(amt0Max, slippage);
        uint amt1Min = wmul(amt1Max, slippage);

        require(
            depositData.amount0In >= amt0Min && depositData.amount1In >= amt1Min,
            "below min amounts"
        );

        if (depositData.amount0In > 0) {
            IERC20 _token0 = depositData.poolContract.token0();
            convertEthToWeth(address(_token0) == wethAddr, TokenInterface(address(_token0)), depositData.amount0In);
            approve(TokenInterface(address(_token0)), address(pool), depositData.amount0In);
        }
        if (depositData.amount1In > 0) {
            IERC20 _token1 = depositData.poolContract.token1();
            convertEthToWeth(address(_token1) == wethAddr, TokenInterface(address(_token1)), depositData.amount1In);
            approve(TokenInterface(address(_token1)), address(pool), depositData.amount1In);
        }

        (uint amount0, uint amount1,) = depositData.poolContract.mint(depositData.mintAmount, address(this));

        require(
            amount0 == depositData.amount0In &&
            amount1 == depositData.amount1In, "unexpected amounts deposited");

        setUint(setId, depositData.mintAmount);

        _eventName = "LogDepositLiquidity(address,uint256,uint256,uint256,uint256[],uint256)";
        _eventParam = abi.encode(pool, amount0, amount1, depositData.mintAmount, getIds, setId);
    }


    /**
     * @dev Withdraw Liquidity.
     * @notice Withdraw Liquidity from Gelato Uniswap V3 pool.
     * @param pool The address of pool.
     * @param liqAmt Amount0 Max amount
     * @param minAmtA Min AmountA amount
     * @param minAmtB Min AmountB amount
     * @param getId ID to retrieve liqAmt.
     * @param setIds Array of IDs tp stores the amounts of pools tokens received.
    */
    function withdraw(
        address pool,
        uint256 liqAmt,
        uint256 minAmtA,
        uint256 minAmtB,
        uint256 getId,
        uint256[] calldata setIds
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {

        liqAmt = getUint(getId, liqAmt);

        IGUniPool poolContract = IGUniPool(pool);

        (uint amount0, uint amount1, uint128 liquidityBurned) = poolContract.burn(liqAmt, address(this));

        if (amount0 > 0) {
            IERC20 _token0 = poolContract.token0();
            convertWethToEth(address(_token0) == wethAddr, TokenInterface(address(_token0)), amount0);
        }

        if (amount1 > 0) {
            IERC20 _token1 = poolContract.token1();
            convertWethToEth(address(_token1) == wethAddr, TokenInterface(address(_token1)), amount1);
        }

        require(amount0 >= minAmtA && amount1 >= minAmtB, "received below minimum");

        setUint(setIds[0], amount0);
        setUint(setIds[1], amount1);

        _eventName = "LogWithdrawLiquidity(address,uint256,uint256,uint256,uint256,uint256[])";
        _eventParam = abi.encode(pool, amount0, amount1, uint256(liquidityBurned), getId, setIds);
    }

    /**
     * @dev Swap & Deposit Liquidity.
     * @notice Withdraw Liquidity to Gelato Uniswap V3 pool.
     * @param pool The address of pool.
     * @param amount0In amount of token0 to deposit.
     * @param amount1In amount of token1 to deposit.
     * @param zeroForOne Swap excess of one token to deposit in equal ratio.
     * @param swapAmount Amount of tokens to swap
     * @param swapThreshold Slippage that the swap could take.
     * @param getId Not used anywhere here.
     * @param setId Set the amount of tokens minted.
    */
    function swapAndDeposit(
        address pool,
        uint256 amount0In,
        uint256 amount1In,
        bool zeroForOne,
        uint256 swapAmount,
        uint160 swapThreshold,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        DepositAndSwap memory depositAndSwap;
        depositAndSwap.poolContract = IGUniPool(pool);
        depositAndSwap._token0 = depositAndSwap.poolContract.token0();
        depositAndSwap._token1 = depositAndSwap.poolContract.token1();

        depositAndSwap.amount0;
        depositAndSwap.amount1;
        depositAndSwap.mintAmount;

        if (address(depositAndSwap._token0) == wethAddr) {
            approve(TokenInterface(address(depositAndSwap._token1)), address(gUniRouter), amount1In);
    
            (depositAndSwap.amount0, depositAndSwap.amount1, depositAndSwap.mintAmount) = 
                gUniRouter.rebalanceAndAddLiquidityETH{value: amount0In}(
                    depositAndSwap.poolContract,
                    amount0In,
                    amount1In,
                    zeroForOne,
                    swapAmount,
                    swapThreshold,
                    0,
                    0,
                    address(this)
                );
        } else if (address(depositAndSwap._token1) == wethAddr) {
            approve(TokenInterface(address(depositAndSwap._token0)), address(gUniRouter), amount0In);

            (depositAndSwap.amount0, depositAndSwap.amount1,depositAndSwap. mintAmount) = 
                gUniRouter.rebalanceAndAddLiquidityETH{value: amount1In}(
                    depositAndSwap.poolContract,
                    amount0In,
                    amount1In,
                    zeroForOne,
                    swapAmount,
                    swapThreshold,
                    0,
                    0,
                    address(this)
                );
        } else {
            approve(TokenInterface(address(depositAndSwap._token0)), address(gUniRouter), amount0In);
            approve(TokenInterface(address(depositAndSwap._token1)), address(gUniRouter), amount1In);
            (depositAndSwap.amount0, depositAndSwap.amount1, depositAndSwap.mintAmount) = 
                gUniRouter.rebalanceAndAddLiquidity(
                    depositAndSwap.poolContract,
                    amount0In,
                    amount1In,
                    zeroForOne,
                    swapAmount,
                    swapThreshold,
                    0,
                    0,
                    address(this)
                );
        }

        setUint(setId, depositAndSwap.mintAmount);

        _eventName = "LogSwapAndDepositLiquidity(address,uint256,uint256,uint256,bool,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            pool,
            depositAndSwap.amount0,
            depositAndSwap.amount1,
            depositAndSwap.mintAmount,
            zeroForOne,
            swapAmount,
            getId,
            setId
        );

    }

}

contract ConnectV2GUniswapV3ERC20 is UniswapV3Resolver {
    string public constant name = "G-Uniswap-v3-ERC20-v1.0";
}
