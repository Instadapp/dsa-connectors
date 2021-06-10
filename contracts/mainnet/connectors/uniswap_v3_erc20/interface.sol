pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IGUniPool {

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function mint(
        uint256 amount,
        address receiver
    ) external
    returns (
        uint256 amount0,
        uint256 amount1,
        uint256 mintAmount
    );

    function burn(
        uint256 _burnAmount,
        address _receiver
    ) external
    returns (
        uint256 amount0,
        uint256 amount1,
        uint128 liquidityBurned
    );

    function getMintAmounts(
        uint256 amount0Max,
        uint256 amount1Max
    ) external view
    returns (
        uint256 amount0,
        uint256 amount1,
        uint256 mintAmount
    );

}


interface IGUniRouter {
    function rebalanceAndAddLiquidity(
        IGUniPool pool,
        uint256 amount0In,
        uint256 amount1In,
        bool zeroForOne,
        uint256 swapAmount,
        uint160 swapThreshold,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        );

    function rebalanceAndAddLiquidityETH(
        IGUniPool pool,
        uint256 amount0In,
        uint256 amount1In,
        bool zeroForOne,
        uint256 swapAmount,
        uint160 swapThreshold,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        payable
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        );

    function removeLiquidity(
        IGUniPool pool,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        );

    function removeLiquidityETH(
        IGUniPool pool,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address payable receiver
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        );
}

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}