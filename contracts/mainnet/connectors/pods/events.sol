pragma solidity ^0.7.0;

contract Events {
    event LogAddLiquidity(
        address indexed pool,
        uint256 amtA,
        uint256 amtB,
        address owner
    );

    event LogRemoveLiquidity(address indexed pool, uint256 amtA, uint256 amtB);

    event LogWithdrawRewards(address indexed pool);
}
