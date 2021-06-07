pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ERC20WrapperInterface {

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function mint(
        uint256 amount0Max,
        uint256 amount1Max,
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

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}