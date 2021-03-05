pragma solidity ^0.7.0;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { InstaPoolFeeInterface, LiqudityInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {

    using SafeERC20 for IERC20;

    /**
     * @dev Instapool Helper
     */
    LiqudityInterface internal constant instaPool = LiqudityInterface(0x06cB7C24990cBE6b9F99982f975f9147c000fec6);

    /**
     * @dev Instapool Fee
     */
    InstaPoolFeeInterface internal constant instaPoolFee = InstaPoolFeeInterface(0xAaA91046C1D1a210017e36394C83bD5070dadDa5);

    function _transfer(address payable to, IERC20 token, uint _amt) internal {
        address(token) == ethAddr ?
            to.transfer(_amt) :
            token.safeTransfer(to, _amt);
    }

    function _getBalance(IERC20 token) internal view returns (uint256) {
        return address(token) == ethAddr ?
            address(this).balance :
            token.balanceOf(address(this));
    }

    function calculateTotalFeeAmt(IERC20 token, uint amt) internal view returns (uint totalAmt) {
        uint fee = instaPoolFee.fee();
        uint flashAmt = instaPool.borrowedToken(address(token));
        if (fee == 0) {
            totalAmt = amt;
        } else {
            uint feeAmt = wmul(flashAmt, fee);
            totalAmt = add(amt, feeAmt);
        }
    }

    function calculateFeeAmt(IERC20 token, uint amt) internal view returns (address feeCollector, uint feeAmt) {
        uint fee = instaPoolFee.fee();
        feeCollector = instaPoolFee.feeCollector();
        if (fee == 0) {
            feeAmt = 0;
        } else {
            feeAmt = wmul(amt, fee);
            uint totalAmt = add(amt, feeAmt);

            uint totalBal = _getBalance(token);
            require(totalBal >= totalAmt - 10, "Not-enough-balance");
            feeAmt = totalBal > totalAmt ? feeAmt : sub(totalBal, amt);
        }
    }

    function calculateFeeAmtOrigin(IERC20 token, uint amt)
        internal
        view
    returns (
        address feeCollector,
        uint poolFeeAmt,
        uint originFee
    )
    {
        uint feeAmt;
        (feeCollector, feeAmt) = calculateFeeAmt(token, amt);
        if (feeAmt == 0) {
            poolFeeAmt = 0;
            originFee = 0;
        } else {
            originFee = wmul(feeAmt, 20 * 10 ** 16); // 20%
            poolFeeAmt = sub(feeAmt, originFee);
        }
    }
}
