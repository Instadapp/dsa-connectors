pragma solidity ^0.7.0;

/**
 * @title Uniswap V3 ERC20 Wrapper.
 * @dev Uniswap V3 Wrapper to deposit and withdraw.
 */

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { TokenInterface } from "../../common/interfaces.sol";
import { ERC20WrapperInterface, IERC20 } from "./interface.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract UniswapV3Resolver is Events, Helpers {
    using SafeERC20 for IERC20;

    /**
     * @dev Deposit Liquidity.
     * @notice Deposit Liquidity to a Uniswap V3 pool.
     * @param pool The address of pool.
     * @param amt0Max Amount0 Max amount
     * @param amt1Max Amount1 Max amount
     * @param slippage use to calculate minimum deposit. 100% = 1e18
     * @param getId ID to retrieve amount.
     * @param setId ID stores the amount of pools tokens received.
    */
    function deposit(
        address pool,
        uint256 amt0Max,
        uint256 amt1Max,
        uint slippage,
        uint256[] getIds,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {

        amt0Max = getUint(getIds[0], amt0Max);
        amt1Max = getUint(getIds[1], amt1Max);

        ERC20WrapperInterface poolContract = ERC20WrapperInterface(pool);

        (uint256 amount0In, uint256 amount1In, uint256 mintAmount) = poolContract.getMintAmounts(amt0Max, amt1Max);

        uint amt0Min = wmul(amt0Max, slippage);
        uint amt1Min = wmul(amt1Max, slippage);

        require(
            amount0In >= amt0Min && amount1In >= amt1Min,
            "below min amounts"
        );

        if (amount0In > 0) {
            IERC20 _token0 = poolContract.token0();
            convertEthToWeth(address(_token0) == wethAddr, TokenInterface(address(_token0)), amount0In);
            _token0.safeApprove(address(pool), amount0In);
        }
        if (amount1In > 0) {
            IERC20 _token1 = poolContract.token1();
            convertEthToWeth(address(_token1) == wethAddr, TokenInterface(address(_token1)), amount1In);
            _token1.safeApprove(address(pool), amount1In);
        }

        (uint amount0, uint amount1,) = poolContract.mint(mintAmount, address(this));

        require(amount0 == amount0In && amount1 == amount1In, "unexpected amounts deposited");

        setUint(setId, mintAmount);

        _eventName = "LogDepositLiquidity(address,uint256,uint256,uint256,uint256[],uint256)";
        _eventParam = abi.encode(pool, amount0, amount1, mintAmount, getIds, setId);
    }


    /**
     * @dev Withdraw Liquidity.
     * @notice Withdraw Liquidity from a Uniswap V3 pool.
     * @param pool The address of pool.
     * @param liqAmt Amount0 Max amount
     * @param minAmtA Min AmountA amount
     * @param minAmtB Min AmountB amount
     * @param getId ID to retrieve liqAmt.
     * @param setId ID stores the amount of pools tokens received.
    */
    function withdraw(
        address pool,
        uint256 liqAmt,
        uint256 minAmtA,
        uint256 minAmtB,
        uint256 getId,
        uint256[] setIds
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {

        liqAmt = getUint(getId, liqAmt);

        ERC20WrapperInterface poolContract = ERC20WrapperInterface(pool);

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

        ERC20WrapperInterface poolContract = ERC20WrapperInterface(pool);
        IERC20 _token0 = poolContract.token0();
        IERC20 _token1 = poolContract.token1();

        uint amount0;
        uint amount1;
        uint mintAmount;

        if (address(_token0) == wethAddr) {
            _token1.approve(address(gUniRouter), amount1In);
            (amount0, amount1, mintAmount) = gUniRouter.rebalanceAndAddLiquidityETH{value: amount0In}(
                poolContract,
                amount0In,
                amount1In,
                zeroForOne,
                swapAmount,
                swapThreshold,
                0,
                0,
                address(this)
            );
        } else if (address(_token1) == wethAddr) {
            _token0.approve(address(gUniRouter), amount0In);
            (amount0, amount1, mintAmount) = gUniRouter.rebalanceAndAddLiquidityETH{value: amount1In}(
                poolContract,
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
            _token0.approve(address(gUniRouter), amount0In);
            _token1.approve(address(gUniRouter), amount1In);
            (amount0, amount1, mintAmount) = gUniRouter.rebalanceAndAddLiquidity(
                poolContract,
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

        setUint(setId, mintAmount);

        _eventName = "LogSwapAndDepositLiquidity(address,uint256,uint256,uint256,bool,uint256,uint256,uint256)";
        _eventParam = abi.encode(pool, amount0, amount1, mintAmount, zeroForOne, swapAmount, getId, setId);

    }

}

contract ConnectV2UniswapV3ERC20 is UniswapV3Resolver {

    string public constant name = "Uniswap-v3-ERC20";

}
