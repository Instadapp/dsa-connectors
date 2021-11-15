pragma solidity ^0.7.0;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {IQuickSwapRouter, IQuickSwapFactory} from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev IQuickSwapRouter
     */
    IQuickSwapRouter internal constant router =
        IQuickSwapRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    function getExpectedBuyAmt(address[] memory paths, uint256 sellAmt)
        internal
        view
        returns (uint256 buyAmt)
    {
        uint256[] memory amts = router.getAmountsOut(sellAmt, paths);
        buyAmt = amts[1];
    }

    function getExpectedSellAmt(address[] memory paths, uint256 buyAmt)
        internal
        view
        returns (uint256 sellAmt)
    {
        uint256[] memory amts = router.getAmountsIn(buyAmt, paths);
        sellAmt = amts[0];
    }

    function checkPair(address[] memory paths) internal view {
        address pair = IQuickSwapFactory(router.factory()).getPair(
            paths[0],
            paths[1]
        );
        require(pair != address(0), "No-exchange-address");
    }

    function getPaths(address buyAddr, address sellAddr)
        internal
        pure
        returns (address[] memory paths)
    {
        paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
    }

    function getMinAmount(
        TokenInterface token,
        uint256 amt,
        uint256 slippage
    ) internal view returns (uint256 minAmt) {
        uint256 _amt18 = convertTo18(token.decimals(), amt);
        minAmt = wmul(_amt18, sub(WAD, slippage));
        minAmt = convert18ToDec(token.decimals(), minAmt);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 _amt,
        uint256 unitAmt,
        uint256 slippage
    )
        internal
        returns (
            uint256 _amtA,
            uint256 _amtB,
            uint256 _liquidity
        )
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeMaticAddress(
            tokenA,
            tokenB
        );

        _amtA = _amt == uint256(-1)
            ? getTokenBal(TokenInterface(tokenA))
            : _amt;
        _amtB = convert18ToDec(
            _tokenB.decimals(),
            wmul(unitAmt, convertTo18(_tokenA.decimals(), _amtA))
        );

        bool isMatic = address(_tokenA) == wmaticAddr;
        convertMaticToWmatic(isMatic, _tokenA, _amtA);

        isMatic = address(_tokenB) == wmaticAddr;
        convertMaticToWmatic(isMatic, _tokenB, _amtB);

        approve(_tokenA, address(router), _amtA);
        approve(_tokenB, address(router), _amtB);

        uint256 minAmtA = getMinAmount(_tokenA, _amtA, slippage);
        uint256 minAmtB = getMinAmount(_tokenB, _amtB, slippage);
        (_amtA, _amtB, _liquidity) = router.addLiquidity(
            address(_tokenA),
            address(_tokenB),
            _amtA,
            _amtB,
            minAmtA,
            minAmtA,
            address(this),
            block.timestamp + 1
        );
    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 _amt,
        uint256 unitAmtA,
        uint256 unitAmtB
    )
        internal
        returns (
            uint256 _amtA,
            uint256 _amtB,
            uint256 _uniAmt
        )
    {
        TokenInterface _tokenA;
        TokenInterface _tokenB;
        (_tokenA, _tokenB, _uniAmt) = _getRemoveLiquidityData(
            tokenA,
            tokenB,
            _amt
        );
        {
            uint256 minAmtA = convert18ToDec(
                _tokenA.decimals(),
                wmul(unitAmtA, _uniAmt)
            );
            uint256 minAmtB = convert18ToDec(
                _tokenB.decimals(),
                wmul(unitAmtB, _uniAmt)
            );
            (_amtA, _amtB) = router.removeLiquidity(
                address(_tokenA),
                address(_tokenB),
                _uniAmt,
                minAmtA,
                minAmtB,
                address(this),
                block.timestamp + 1
            );
        }

        bool isMatic = address(_tokenA) == wmaticAddr;
        convertWmaticToMatic(isMatic, _tokenA, _amtA);

        isMatic = address(_tokenB) == wmaticAddr;
        convertWmaticToMatic(isMatic, _tokenB, _amtB);
    }

    function _getRemoveLiquidityData(
        address tokenA,
        address tokenB,
        uint256 _amt
    )
        internal
        returns (
            TokenInterface _tokenA,
            TokenInterface _tokenB,
            uint256 _uniAmt
        )
    {
        (_tokenA, _tokenB) = changeMaticAddress(tokenA, tokenB);
        address exchangeAddr = IQuickSwapFactory(router.factory()).getPair(
            address(_tokenA),
            address(_tokenB)
        );
        require(exchangeAddr != address(0), "pair-not-found.");

        TokenInterface uniToken = TokenInterface(exchangeAddr);
        _uniAmt = _amt == uint256(-1)
            ? uniToken.balanceOf(address(this))
            : _amt;
        approve(uniToken, address(router), _uniAmt);
    }
}
