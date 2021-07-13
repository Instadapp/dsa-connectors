pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title dYdX.
 * @dev Lending & Borrowing.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract DyDxResolver is Events, Helpers {

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @notice Deposit a token to dYdX for lending / collaterization.
     * @param token token address to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to deposit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(
        address token,
        uint amt,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _marketId = getMarketId(token);

        (uint depositedAmt, bool sign) = getDydxPosition(_marketId);
        require(depositedAmt == 0 || sign, "token-borrowed");

        if (token == ethAddr) {
            TokenInterface tokenContract = TokenInterface(wethAddr);
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            tokenContract.deposit{value: _amt}();
            approve(tokenContract, address(solo), _amt);
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            approve(tokenContract, address(solo), _amt);
        }

        solo.operate(getAccountArgs(), getActionsArgs(_marketId, _amt, true));
        setUint(setId, _amt);

        _eventName = "LogDeposit(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _marketId, _amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @notice Withdraw deposited token from dYdX.
     * @param token token address to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdraw(
        address token,
        uint amt,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _marketId = getMarketId(token);

        (uint depositedAmt, bool sign) = getDydxPosition(_marketId);
        require(sign, "try-payback");

        _amt = _amt == uint(-1) ? depositedAmt : _amt;
        require(_amt <= depositedAmt, "withdraw-exceeds");

        solo.operate(getAccountArgs(), getActionsArgs(_marketId, _amt, false));

        if (token == ethAddr) {
            TokenInterface tokenContract = TokenInterface(wethAddr);
            approve(tokenContract, address(tokenContract), _amt);
            tokenContract.withdraw(_amt);
        }

        setUint(setId, _amt);

        _eventName = "LogWithdraw(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _marketId, _amt, getId, setId);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @notice Borrow a token using dYdX
     * @param token token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to borrow.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function borrow(
        address token,
        uint amt,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _marketId = getMarketId(token);

        (uint borrowedAmt, bool sign) = getDydxPosition(_marketId);
        require(borrowedAmt == 0 || !sign, "token-deposited");

        solo.operate(getAccountArgs(), getActionsArgs(_marketId, _amt, false));

        if (token == ethAddr) {
            TokenInterface tokenContract = TokenInterface(wethAddr);
            approve(tokenContract, address(tokenContract), _amt);
            tokenContract.withdraw(_amt);
        }

        setUint(setId, _amt);

        _eventName = "LogBorrow(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _marketId, _amt, getId, setId);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @notice Payback debt owed.
     * @param token token address to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to payback.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function payback(
        address token,
        uint amt,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _marketId = getMarketId(token);

        (uint borrowedAmt, bool sign) = getDydxPosition(_marketId);
        require(!sign, "try-withdraw");

        _amt = _amt == uint(-1) ? borrowedAmt : _amt;
        require(_amt <= borrowedAmt, "payback-exceeds");

        if (token == ethAddr) {
            TokenInterface tokenContract = TokenInterface(wethAddr);
            require(address(this).balance >= _amt, "not-enough-eth");
            tokenContract.deposit{value: _amt}();
            approve(tokenContract, address(solo), _amt);
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            approve(tokenContract, address(solo), _amt);
        }

        solo.operate(getAccountArgs(), getActionsArgs(_marketId, _amt, true));
        setUint(setId, _amt);

        _eventName = "LogPayback(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _marketId, _amt, getId, setId);
    }

}

contract ConnectV2Dydx is DyDxResolver {
    string public name = "Dydx-v1";
}
