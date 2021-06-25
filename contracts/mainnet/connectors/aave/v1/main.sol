pragma solidity ^0.7.0;


/**
 * @title Aave v1.
 * @dev Lending & Borrowing.
 */

import { TokenInterface } from "../../../common/interfaces.sol";
import { Stores } from "../../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { AaveInterface, AaveCoreInterface, ATokenInterface } from "./interface.sol";

abstract contract AaveResolver is Events, Helpers {
    /**
     * @dev Deposit ETH/ERC20_Token.
     * @notice Deposit a token to Aave v1 for lending / collaterization.
     * @param token The address of the token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function deposit(
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        uint ethAmt;
        if (token == ethAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            ethAmt = _amt;
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            approve(tokenContract, aaveProvider.getLendingPoolCore(), _amt);
        }

        aave.deposit{value: ethAmt}(token, _amt, referralCode);

        if (!getIsColl(aave, token)) aave.setUserUseReserveAsCollateral(token, true);

        setUint(setId, _amt);

        _eventName = "LogDeposit(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @notice Withdraw deposited token from Aave v1
     * @param token The address of the token to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdraw(
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        AaveCoreInterface aaveCore = AaveCoreInterface(aaveProvider.getLendingPoolCore());
        ATokenInterface atoken = ATokenInterface(aaveCore.getReserveATokenAddress(token));
        TokenInterface tokenContract = TokenInterface(token);

        uint initialBal = token == ethAddr ? address(this).balance : tokenContract.balanceOf(address(this));
        atoken.redeem(_amt);
        uint finalBal = token == ethAddr ? address(this).balance : tokenContract.balanceOf(address(this));

        _amt = sub(finalBal, initialBal);
        setUint(setId, _amt);

        _eventName = "LogWithdraw(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, getId, setId);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @notice Borrow a token using Aave v1
     * @param token The address of the token to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt The amount of the token to borrow.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens borrowed.
    */
    function borrow(
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());
        aave.borrow(token, _amt, 2, referralCode);
        setUint(setId, _amt);

        _eventName = "LogBorrow(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, getId, setId);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @notice Payback debt owed.
     * @param token The address of the token to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt The amount of the token to payback. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens paid back.
    */
    function payback(
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        if (_amt == uint(-1)) {
            uint fee;
            (_amt, fee) = getPaybackBalance(aave, token);
            _amt = add(_amt, fee);
        }
        uint ethAmt;
        if (token == ethAddr) {
            ethAmt = _amt;
        } else {
            approve(TokenInterface(token), aaveProvider.getLendingPoolCore(), _amt);
        }

        aave.repay{value: ethAmt}(token, _amt, payable(address(this)));

        setUint(setId, _amt);

        _eventName = "LogPayback(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, getId, setId);
    }

    /**
     * @dev Enable collateral
     * @notice Enable an array of tokens as collateral
     * @param tokens Array of tokens to enable collateral
    */
    function enableCollateral(
        address[] calldata tokens
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _length = tokens.length;
        require(_length > 0, "0-tokens-not-allowed");

        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        for (uint i = 0; i < _length; i++) {
            address token = tokens[i];
            if (getCollateralBalance(aave, token) > 0 && !getIsColl(aave, token)) {
                aave.setUserUseReserveAsCollateral(token, true);
            }
        }

        _eventName = "LogEnableCollateral(address[]);";
        _eventParam = abi.encode(tokens);
    }
}

contract ConnectV2AaveV1 is AaveResolver {
    string constant public name = "AaveV1-v1.1";
}
