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
     * @param amt0Min Amount0 Min amount
     * @param amt1Max Amount1 Max amount
     * @param amt1Min Amount1 Min amount
     * @param getId ID to retrieve amount.
     * @param setId ID stores the amount of pools tokens received.
    */
    function deposit(
        address pool,
        uint256 amt0Max,
        uint256 amt0Min,
        uint256 amt1Max,
        uint256 amt1Min,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {

        ERC20WrapperInterface poolContract = ERC20WrapperInterface(pool);

        (uint256 amount0In, uint256 amount1In, uint256 mintAmount) = poolContract.getMintAmounts(amt0Max, amt1Max);

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

        _eventName = "LogDepositLiquidity(address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(pool, amount0, amount1, mintAmount, getId, setId);
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
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {

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

        _eventName = "LogWithdrawLiquidity(address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(pool, amount0, amount1, uint256(liquidityBurned), getId, setId);
    }

}

contract ConnectV2UniswapV3ERC20 is UniswapV3Resolver {

    string public constant name = "Uniswap-v3-ERC20";

}
