pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Instapool.
 * @dev Flash Loan in DSA.
 */

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { AccountInterface } from "./interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Stores } from "../../common/stores.sol";
import { Variables } from "./variables.sol";
import { Events } from "./events.sol";

contract LiquidityResolver is DSMath, Stores, Variables, Events {
    using SafeERC20 for IERC20;

    /**
     * @dev Borrow Flashloan and Cast spells.
     * @param token Token Address.
     * @param amt Token Amount.
     * @param data targets & data for cast.
     */
    function flashBorrowAndCast(
        address token,
        uint amt,
        uint route,
        bytes memory data
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        AccountInterface(address(this)).enable(address(instaPool));

        address[] memory tokens = new address[](1);
        uint[] memory amts = new uint[](1);
        tokens[0] = token;
        amts[0] = amt;

        instaPool.initiateFlashLoan(tokens, amts, route, data);

        AccountInterface(address(this)).disable(address(instaPool));

        _eventName = "LogFlashBorrow(address,uint256)";
        _eventParam = abi.encode(token, amt);
    }

    /**
     * @dev Return token to InstaPool.
     * @param token Token Address.
     * @param amt Token Amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function flashPayback(
        address token,
        uint amt,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        
        IERC20 tokenContract = IERC20(token);

        tokenContract.safeTransfer(address(instaPool), _amt);

        setUint(setId, _amt);

        _eventName = "LogFlashPayback(address,uint256)";
        _eventParam = abi.encode(token, _amt);
    }

    /**
     * @dev Borrow Flashloan and Cast spells.
     * @param tokens Array of token Addresses.
     * @param amts Array of token Amounts.
     * @param route Route to borrow.
     * @param data targets & data for cast.
     */
    function flashMultiBorrowAndCast(
        address[] calldata tokens,
        uint[] calldata amts,
        uint route,
        bytes calldata data
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        AccountInterface(address(this)).enable(address(instaPool));

        instaPool.initiateFlashLoan(tokens, amts, route, data);

        AccountInterface(address(this)).disable(address(instaPool));

        _eventName = "LogFlashMultiBorrow(address[],uint256[])";
        _eventParam = abi.encode(tokens, amts);
    }

    /**
     * @dev Return Multiple token liquidity to InstaPool.
     * @param tokens Array of token addresses.
     * @param amts Array of token amounts.
     * @param getId get token amounts at this IDs from `InstaMemory` Contract.
     * @param setId set token amounts at this IDs in `InstaMemory` Contract.
    */
    function flashMultiPayback(
        address[] calldata tokens,
        uint[] calldata amts,
        uint[] calldata getId,
        uint[] calldata setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _length = tokens.length;

        uint[] memory _amts = new uint[](_length);

        for (uint i = 0; i < _length; i++) {
            uint _amt = getUint(getId[i], amts[i]);

            _amts[i] = _amt;

            IERC20 tokenContract = IERC20(tokens[i]);

            tokenContract.safeTransfer(address(instaPool), _amt);

            setUint(setId[i], _amt);
        }

        _eventName = "LogFlashMultiPayback(address[],uint256[])";
        _eventParam = abi.encode(tokens, _amts);
    }
}

contract ConnectV2InstaPool is LiquidityResolver {
    string public name = "Instapool-v1";
}