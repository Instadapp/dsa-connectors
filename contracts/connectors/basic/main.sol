pragma solidity ^0.7.0;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";

abstract contract BasicResolver is Events, DSMath, Basic {
    using SafeERC20 for IERC20;

    /**
     * @dev Deposit Assets To Smart Account.
     * @param erc20 Token Address.
     * @param tokenAmt Token Amount.
     * @param getId Get Storage ID.
     * @param setId Set Storage ID.
     */
    function deposit(
        address erc20,
        uint tokenAmt,
        uint getId,
        uint setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint amt = getUint(getId, tokenAmt);
        if (erc20 != ethAddr) {
            IERC20 token = IERC20(erc20);
            amt = amt == uint(-1) ? token.balanceOf(msg.sender) : amt;
            token.safeTransferFrom(msg.sender, address(this), amt);
        } else {
            require(msg.value == amt || amt == uint(-1), "invalid-ether-amount");
            amt = msg.value;
        }
        setUint(setId, amt);

        _eventName = "LogDeposit(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(erc20, amt, getId, setId);
    }

    /**
     * @dev Withdraw Assets To Smart Account.
     * @param erc20 Token Address.
     * @param tokenAmt Token Amount.
     * @param to Withdraw token address.
     * @param getId Get Storage ID.
     * @param setId Set Storage ID.
     */
    function withdraw(
        address erc20,
        uint tokenAmt,
        address payable to,
        uint getId,
        uint setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint amt = getUint(getId, tokenAmt);
        if (erc20 == ethAddr) {
            amt = amt == uint(-1) ? address(this).balance : amt;
            to.transfer(amt);
        } else {
            IERC20 token = IERC20(erc20);
            amt = amt == uint(-1) ? token.balanceOf(address(this)) : amt;
            token.safeTransfer(to, amt);
        }
        setUint(setId, amt);

        _eventName = "LogWithdraw(address,uint256,address,uint256,uint256)";
        _eventParam = abi.encode(erc20, amt, to, getId, setId);
    }
}

contract ConnectV2Basic is BasicResolver {
    string public constant name = "Basic-v1.1";
}
