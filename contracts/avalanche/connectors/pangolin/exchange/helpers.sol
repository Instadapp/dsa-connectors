//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { IPangolinRouter, IPangolinFactory } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {

    /**
     * @dev Pangolin Router
     */
    IPangolinRouter internal constant router = IPangolinRouter(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);

    function getExpectedBuyAmt(
        address[] memory paths,
        uint sellAmt
    ) internal view returns(uint buyAmt) {
        uint[] memory amts = router.getAmountsOut(
            sellAmt,
            paths
        );
        buyAmt = amts[1];
    }

    function getExpectedSellAmt(
        address[] memory paths,
        uint buyAmt
    ) internal view returns(uint sellAmt) {
        uint[] memory amts = router.getAmountsIn(
            buyAmt,
            paths
        );
        sellAmt = amts[0];
    }

    function checkPair(
        address[] memory paths
    ) internal view {
        address pair = IPangolinFactory(router.factory()).getPair(paths[0], paths[1]);
        require(pair != address(0), "No-exchange-address");
    }

    function getPaths(
        address buyAddr,
        address sellAddr
    ) internal pure returns(address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
    }

    function getMinAmount(
        TokenInterface token,
        uint amt,
        uint slippage
    ) internal view returns(uint minAmt) {
        uint _amt18 = convertTo18(token.decimals(), amt);
        minAmt = wmul(_amt18, sub(WAD, slippage));
        minAmt = convert18ToDec(token.decimals(), minAmt);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint _amt,
        uint unitAmt,
        uint slippage
    ) internal returns (uint _amtA, uint _amtB, uint _liquidity) {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeAvaxAddress(tokenA, tokenB);

        _amtA = _amt == uint(-1) ? getTokenBal(TokenInterface(tokenA)) : _amt;
        _amtB = convert18ToDec(_tokenB.decimals(), wmul(unitAmt, convertTo18(_tokenA.decimals(), _amtA)));

        bool isAvax = address(_tokenA) == wavaxAddr;
        convertAvaxToWavax(isAvax, _tokenA, _amtA);

        isAvax = address(_tokenB) == wavaxAddr;
        convertAvaxToWavax(isAvax, _tokenB, _amtB);

        approve(_tokenA, address(router), _amtA);
        approve(_tokenB, address(router), _amtB);

        uint minAmtA = getMinAmount(_tokenA, _amtA, slippage);
        uint minAmtB = getMinAmount(_tokenB, _amtB, slippage);
       (_amtA, _amtB, _liquidity) = router.addLiquidity(
            address(_tokenA),
            address(_tokenB),
            _amtA,
            _amtB,
            minAmtA,
            minAmtB,
            address(this),
            block.timestamp + 1
        );
    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint _amt,
        uint unitAmtA,
        uint unitAmtB
    ) internal returns (uint _amtA, uint _amtB, uint _uniAmt) {
        TokenInterface _tokenA;
        TokenInterface _tokenB;
        (_tokenA, _tokenB, _uniAmt) = _getRemoveLiquidityData(
            tokenA,
            tokenB,
            _amt
        );
        {
        uint minAmtA = convert18ToDec(_tokenA.decimals(), wmul(unitAmtA, _uniAmt));
        uint minAmtB = convert18ToDec(_tokenB.decimals(), wmul(unitAmtB, _uniAmt));
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

        bool isAvax = address(_tokenA) == wavaxAddr;
        convertWavaxToAvax(isAvax, _tokenA, _amtA);

        isAvax = address(_tokenB) == wavaxAddr;
        convertWavaxToAvax(isAvax, _tokenB, _amtB);
    }

    function _getRemoveLiquidityData(
        address tokenA,
        address tokenB,
        uint _amt
    ) internal returns (TokenInterface _tokenA, TokenInterface _tokenB, uint _uniAmt) {
        (_tokenA, _tokenB) = changeAvaxAddress(tokenA, tokenB);
        address exchangeAddr = IPangolinFactory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr != address(0), "pair-not-found.");

        TokenInterface pngToken = TokenInterface(exchangeAddr);
        _uniAmt = _amt == uint(-1) ? pngToken.balanceOf(address(this)) : _amt;
        approve(pngToken, address(router), _uniAmt);
    }
}