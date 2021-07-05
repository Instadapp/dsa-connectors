pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IOptionAMMPool {
    function tokenA() external view returns (address);

    function tokenB() external view returns (address);

    function addLiquidity(
        address pool,
        uint256 amountOfA,
        uint256 amountOfB,
        address owner
    ) external;

    function removeLiquidity(uint256 amountOfA, uint256 amountOfB) external;

    function withdrawRewards() external;
}
