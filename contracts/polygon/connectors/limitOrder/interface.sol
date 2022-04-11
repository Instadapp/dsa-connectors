pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

interface IUniLimitOrder {

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount;
        bool tokenDirectn;
    }

    function createPosition(
        MintParams memory params_
    ) external
        returns (
            uint256 tokenId_,
            uint128 liquidity_,
            uint256 mintAmount_
        );


    function closeMidPosition(
        uint256 tokenId_,
        uint256 amount0Min_,
        uint256 amount1Min_
    )
        external
        returns (uint128 liquidity_, uint256 amount0_, uint256 amount1_);

    function closeFullPosition(
        uint256 tokenId_
    )
        external
        returns (uint128 liquidity_);

}
