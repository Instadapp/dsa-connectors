pragma solidity ^0.7.0;

/**
 * @title Authority.
 * @dev Manage Authorities to DSA.
 */

import { ERC20WrapperInterface, IERC20, TokenInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract AuthorityResolver is Events, Helpers {

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

        (uint256 amount0In, uint256 amount1In, ) = poolContract.getMintAmounts(amt0Max, amt1Max);

        require(
            amount0In >= amount0Min && amount1In >= amount1Min,
            "below min amounts"
        );

        if (amount0In > 0) {
            IERC20 _token0 = pool.token0();
            convertEthToWeth(address(_token0) == wethAddr, TokenInterface(address(_token0)), amount0In);
            _token0.safeAllowance(address(pool), amount0In);
        }
        if (amount1In > 0) {
            IERC20 _token1 = pool.token1();
            convertEthToWeth(address(_token1) == wethAddr, TokenInterface(address(_token1)), amount1In);
            _token1.safeAllowance(address(pool), amount1In);
        }

        (uint amount0, uint amount1, uint mintAmount) = poolContract.mint(amount0In, amount1In, address(this));

        require(amount0 == amount0In && amount1 == amount1In, "unexpected amounts deposited");

        _eventName = "LogDepositLiquidity(address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(pool, amount0, amount1, mintAmount, getId, setId);
    }

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
            convertWethToEth(address(_token0) == wethAddr, TokenInterface(address(_token0)), _amt);
        }

        if (amount1 > 0) {
            IERC20 _token1 = poolContract.token1();
            convertWethToEth(address(_token1) == wethAddr, TokenInterface(address(_token1)), _amt);
        }

        require(amount0 >= minAmtA && amount1 >= minAmtB, "received below minimum");

        _eventName = "LogWithdrawLiquidity(address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(pool, amount0, amount1, uint256(liquidityBurned), getId, setId);

    }

}

contract ConnectV2Auth is AuthorityResolver {

    string public constant name = "Uniswap-v3-erc20";

}
