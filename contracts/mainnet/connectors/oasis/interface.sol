pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";

interface OasisInterface {
    function getMinSell(TokenInterface pay_gem) external view returns (uint);
    function getBuyAmount(address dest, address src, uint srcAmt) external view returns(uint);
	function getPayAmount(address src, address dest, uint destAmt) external view returns (uint);
	function sellAllAmount(
        address src,
        uint srcAmt,
        address dest,
        uint minDest
    ) external returns (uint destAmt);
	function buyAllAmount(
        address dest,
        uint destAmt,
        address src,
        uint maxSrc
    ) external returns (uint srcAmt);

    function getBestOffer(TokenInterface sell_gem, TokenInterface buy_gem) external view returns(uint);
}