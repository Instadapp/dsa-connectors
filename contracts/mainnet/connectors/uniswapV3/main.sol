pragma solidity =0.7.6;
pragma abicoder v2;

/**
 * @title Uniswap v3.
 * @dev Decentralized Exchange.
 */

import {TokenInterface} from "../../common/interfaces.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

abstract contract UniswapResolver is Helpers, Events {
    /**
     * @dev Mint New Position
     * @param params: parameter for mint.
     * @param getId: ID to retrieve amtA.
     * @param setId: ID stores the amount of LP token.
     */
    function mint(
        MintParams memory params,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        params.amtA = getUint(getId, params.amtA);
        
        (
            uint256 _tokenID,
            uint256 _amtA,
            uint256 _amtB,
            uint256 liquidity
        ) = _mint(params);
        setUint(setId, liquidity);

        _eventName = "LogMintNewPosition(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(_tokenID, _amtA, _amtB, liquidity);
    }

    /**
     * @dev Increase Liquidity
     * @param tokenId: NFT LP Token ID.
     * @param amountA: tokenA amounts.
     * @param amountB: tokenB amounts.
     * @param amountAMin: Min amount of tokenA.
     * @param amountBMin: Min amount of tokenB.
     * @param getIds: IDs to retrieve token amounts
     * @param  setId: stores the amount of LP token
     */
    function addLiquidity(
        uint256 tokenId,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256[] calldata getIds,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 amtA = getUint(getIds[0], amountA);
        uint256 amtB = getUint(getIds[1], amountB);

        (uint256 _liquidity, uint256 _amtA, uint256 _amtB) = _addLiquidity(
            tokenId,
            amtA,
            amtB,
            amountAMin,
            amountBMin
        );
        setUint(setId, _liquidity);

        _eventName = "LogAddLiquidity(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(tokenId, _amtA, _amtB, _liquidity);
    }

    /**
     * @dev Decrease Liquidity
     * @param tokenId: NFT LP Token ID.
     * @param liquidity: LP Token amount.
     * @param amountAMin: Min amount of tokenA.
     * @param amountBMin: Min amount of tokenB.
     * @param getId: ID to retrieve LP token amounts
     * @param  setIds: stores the amount of output tokens
     */
    function decreateLiquidity(
        uint256 tokenId,
        uint128 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 getId,
        uint256[] calldata setIds
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint128 _liquidity = uint128(getUint(getId, liquidity));

        (uint256 _amtA, uint256 _amtB) = _decreaseLiquidity(
            tokenId,
            _liquidity,
            amountAMin,
            amountBMin
        );

        setUint(setIds[0], _amtA);
        setUint(setIds[1], _amtB);

        _eventName = "LogDecreaseLiquidity(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(tokenId, _liquidity, _amtA, _amtB);
    }

    /**
     * @dev Swap Function
     * @param tokenIn: Token Address for input
     * @param tokenOut: Token Address for output
     * @param fee: Fee amount
     * @param amountIn: Amount for input
     * @param getId: ID to retrieve amountIn
     * @param setId: stores the amount of Out token
     */
    function swapToken(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amountIn = getUint(getId, amountIn);
        uint256 amountOut = _exactInputSingle(
            tokenIn,
            tokenOut,
            fee,
            _amountIn
        );

        setUint(setId, amountOut);

        _eventName = "swap(address,address,uint256,uint256)";
        _eventParam = abi.encode(tokenIn, tokenOut, _amountIn, amountOut);
    }

    /**
     * @dev Collect function
     * @param tokenId: NFT LP Token ID.
     * @param amount0Max: Max amount of token0.
     * @param amount1Max: Max amount of token1.
     * @param  getIds: IDs to retrieve amounts
     * @param  setIds: stores the amount of output tokens
     */
    function collect(
        uint256 tokenId,
        uint128 amount0Max,
        uint128 amount1Max,
        uint256[] calldata getIds,
        uint256[] calldata setIds
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint128 _amount0Max = uint128(getUint(getIds[0], amount0Max));
        uint128 _amount1Max = uint128(getUint(getIds[1], amount1Max));
        (uint256 amount0, uint256 amount1) = _collect(
            tokenId,
            _amount0Max,
            _amount1Max
        );

        setUint(setIds[0], amount0);
        setUint(setIds[1], amount1);
        _eventName = "collect(uint256,uint256,uint256)";
        _eventParam = abi.encode(tokenId, amount0, amount1);
    }
}

contract ConnectV2UniswapV3 is UniswapResolver {
    string public constant name = "UniswapV3-v1.1";
}
