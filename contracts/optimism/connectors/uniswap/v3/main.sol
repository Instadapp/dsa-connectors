// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Uniswap v3.
 * @dev Decentralized Exchange.
 */

import {TokenInterface} from "../../../common/interfaces.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";
import "./interface.sol";

abstract contract UniswapResolver is Helpers, Events {
    /**
     * @dev Mint New Position
     * @notice Mint New NFT LP Position
     * @param tokenA tokenA addreess
     * @param tokenB tokenB addreess
     * @param fee fee percentage
     * @param tickLower Lower tick
     * @param tickUpper Upper tick
     * @param amtA amount of tokenA
     * @param amtB amount of tokenB
     * @param slippage slippage percentage
     * @param getIds ID to retrieve amtA
     * @param setId ID stores the amount of LP token
     */
    function mint(
        address tokenA,
        address tokenB,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amtA,
        uint256 amtB,
        uint256 slippage,
        uint256[] calldata getIds,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {

        MintParams memory params;
        {
            params = MintParams(
                tokenA,
                tokenB,
                fee,
                tickLower,
                tickUpper,
                amtA,
                amtB,
                slippage
            );
        }
        params.amtA = getUint(getIds[0], params.amtA);
        params.amtB = getUint(getIds[1], params.amtB);

        (
            uint256 _tokenId,
            uint256 liquidity,
            uint256 amountA,
            uint256 amountB
        ) = _mint(params);

        setUint(setId, liquidity);

        _eventName = "LogMint(uint256,uint256,uint256,uint256,int24,int24)";
        _eventParam = abi.encode(
            _tokenId,
            liquidity,
            amountA,
            amountB,
            params.tickLower,
            params.tickUpper
        );
    }

    /**
     * @dev Increase Liquidity
     * @notice Increase Liquidity of NFT Position
     * @param tokenId NFT LP Token ID.
     * @param amountA tokenA amounts.
     * @param amountB tokenB amounts.
     * @param slippage slippage.
     * @param getIds IDs to retrieve token amounts
     * @param setId stores the liquidity amount
     */
    function deposit(
        uint256 tokenId,
        uint256 amountA,
        uint256 amountB,
        uint256 slippage,
        uint256[] calldata getIds,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        if (tokenId == 0) tokenId = _getLastNftId(address(this));
        amountA = getUint(getIds[0], amountA);
        amountB = getUint(getIds[1], amountB);
        (
            uint256 _liquidity,
            uint256 _amtA,
            uint256 _amtB
        ) = _addLiquidityWrapper(tokenId, amountA, amountB, slippage);
        setUint(setId, _liquidity);

        _eventName = "LogDeposit(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(tokenId, _liquidity, _amtA, _amtB);
    }

    /**
     * @dev Decrease Liquidity
     * @notice Decrease Liquidity of NFT Position
     * @param tokenId NFT LP Token ID.
     * @param liquidity LP Token amount.
     * @param amountAMin Min amount of tokenA.
     * @param amountBMin Min amount of tokenB.
     * @param getId ID to retrieve LP token amounts
     * @param setIds stores the amount of output tokens
     */
    function withdraw(
        uint256 tokenId,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 getId,
        uint256[] calldata setIds
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        if (tokenId == 0) tokenId = _getLastNftId(address(this));
        uint128 _liquidity = uint128(getUint(getId, liquidity));

        (uint256 _amtA, uint256 _amtB) = _decreaseLiquidity(
            tokenId,
            _liquidity,
            amountAMin,
            amountBMin
        );

        setUint(setIds[0], _amtA);
        setUint(setIds[1], _amtB);

        _eventName = "LogWithdraw(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(tokenId, _liquidity, _amtA, _amtB);
    }

    /**
     * @dev Collect function
     * @notice Collect from NFT Position
     * @param tokenId NFT LP Token ID.
     * @param amount0Max Max amount of token0.
     * @param amount1Max Max amount of token1.
     * @param getIds IDs to retrieve amounts
     * @param setIds stores the amount of output tokens
     */
    function collect(
        uint256 tokenId,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256[] calldata getIds,
        uint256[] calldata setIds
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        if (tokenId == 0) tokenId = _getLastNftId(address(this));
        uint128 _amount0Max = uint128(getUint(getIds[0], amount0Max));
        uint128 _amount1Max = uint128(getUint(getIds[1], amount1Max));
        (uint256 amount0, uint256 amount1) = _collect(
            tokenId,
            _amount0Max,
            _amount1Max
        );

        setUint(setIds[0], amount0);
        setUint(setIds[1], amount1);
        _eventName = "LogCollect(uint256,uint256,uint256)";
        _eventParam = abi.encode(tokenId, amount0, amount1);
    }

    /**
     * @dev Burn Function
     * @notice Burn NFT LP Position
     * @param tokenId NFT LP Token ID
     */
    function burn(uint256 tokenId)
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        if (tokenId == 0) tokenId = _getLastNftId(address(this));
        _burn(tokenId);
        _eventName = "LogBurnPosition(uint256)";
        _eventParam = abi.encode(tokenId);
    }

     /**
     * @dev Buy Function
     * @notice Swap token(sellAddr) with token(buyAddr), buy token with minimum sell token
     * @param buyAddr token to be bought
     * @param sellAddr token to be sold
     * @param fee pool fees for buyAddr-sellAddr token pair
     * @param buyAmt amount of token to be bought
     * @param getId Id to get buyAmt
     * @param setId Id to store sellAmt
     */
    function buy(
        address buyAddr,
        address sellAddr,
        uint24 fee,
        uint256 buyAmt,
        uint256 unitAmt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _buyAmt = getUint(getId, buyAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);

        // uint _slippageAmt = convert18ToDec(_sellAddr.decimals(),
        //     wmul(unitAmt, convertTo18(_buyAddr.decimals(), _buyAmt))
        // );

        bool isEth = address(_sellAddr) == wethAddr;
        convertEthToWeth(isEth, _sellAddr, uint256(-1));
        approve(_sellAddr, address(swapRouter), uint256(-1));
        ISwapRouter.ExactOutputSingleParams memory params;

        {
            params = ISwapRouter.ExactOutputSingleParams({
                tokenIn: sellAddr,
                tokenOut: buyAddr,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp + 1,
                amountOut: _buyAmt,
                amountInMaximum: uint256(-1),
                sqrtPriceLimitX96: 0
            }); 
        }

        uint _sellAmt = swapRouter.exactOutputSingle(params);

        isEth = address(_buyAddr) == wethAddr;
        convertWethToEth(isEth, _buyAddr, _buyAmt);

        setUint(setId, _sellAmt);

        _eventName = "LogBuy(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
    }

    /**
     * @dev Sell Function
     * @notice Swap token(sellAddr) with token(buyAddr), sell token to get maximum amount of buy token
     * @param buyAddr token to be bought
     * @param sellAddr token to be sold
     * @param fee pool fees for buyAddr-sellAddr token pair
     * @param sellAmt amount of token to be sold
     * @param getId Id to get sellAmount
     * @param setId Id to store buyAmount
     */
    function sell(
        address buyAddr,
        address sellAddr,
        uint24 fee,
        uint256 sellAmt,
        uint256 unitAmt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _sellAmt = getUint(getId, sellAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);

        if (_sellAmt == uint(-1)) {
            _sellAmt = sellAddr == ethAddr ?
                address(this).balance :
                _sellAddr.balanceOf(address(this));
        }

        // uint _slippageAmt = convert18ToDec(_buyAddr.decimals(),
        //     wmul(unitAmt, convertTo18(_sellAddr.decimals(), _sellAmt))
        // );
        // require(_slippageAmt <= _expectedAmt, "Too much slippage");

        bool isEth = address(_sellAddr) == wethAddr;
        convertEthToWeth(isEth, _sellAddr, _sellAmt);
        approve(_sellAddr, address(swapRouter), _sellAmt);
        ISwapRouter.ExactInputSingleParams memory params;

        {
            params = ISwapRouter.ExactInputSingleParams({
                tokenIn: sellAddr,
                tokenOut: buyAddr,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp + 1,
                amountIn: _sellAmt,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0               
            }); 
        }

        uint _buyAmt = swapRouter.exactInputSingle(params);

        isEth = address(_buyAddr) == wethAddr;
        convertWethToEth(isEth, _buyAddr, _buyAmt);

        setUint(setId, _buyAmt);

        _eventName = "LogSell(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
    }
}

contract ConnectV2UniswapV3Optimism is UniswapResolver {
    string public constant name = "UniswapV3-v1";
}
