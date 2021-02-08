pragma solidity ^0.7.0;

import { TokenInterface } from "../../../common/interfaces.sol";
import { Stores } from "../../../common/stores.sol";
import { Utils } from "../../../common/utils.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { AaveInterface } from "./interface.sol";

abstract contract AaveResolver is Events, Helpers, Utils {
    /**
     * @dev Deposit ETH/ERC20_Token.
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

        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        bool isEth = token == ethAddr;
        address _token = isEth ? wethAddr : token;

        TokenInterface tokenContract = TokenInterface(_token);

        if (isEth) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            convertEthToWeth(isEth, tokenContract, _amt);
        } else {
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
        }

        tokenContract.approve(address(aave), _amt);

        aave.deposit(_token, _amt, address(this), referralCode);

        if (!getIsColl(_token)) {
            aave.setUserUseReserveAsCollateral(_token, true);
        }

        setUint(setId, _amt);

        _eventName = "LogDeposit(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
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

        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());
        bool isEth = token == ethAddr;
        address _token = isEth ? wethAddr : token;

        TokenInterface tokenContract = TokenInterface(_token);

        uint initialBal = tokenContract.balanceOf(address(this));
        aave.withdraw(_token, _amt, address(this));
        uint finalBal = tokenContract.balanceOf(address(this));

        _amt = sub(finalBal, initialBal);

        convertWethToEth(isEth, tokenContract, _amt);
        
        setUint(setId, _amt);

        _eventName = "LogWithdraw(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, getId, setId);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @param token token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to borrow.
     * @param rateMode type of borrow debt.(For Stable: 1, Variable: 2)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function borrow(
        address token,
        uint amt,
        uint rateMode,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        bool isEth = token == ethAddr;
        address _token = isEth ? wethAddr : token;

        aave.borrow(_token, _amt, rateMode, referralCode, address(this));
        convertWethToEth(isEth, TokenInterface(_token), _amt);

        setUint(setId, _amt);

        _eventName = "LogBorrow(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, rateMode, getId, setId);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @param token token address to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to payback.
     * @param rateMode type of borrow debt.(For Stable: 1, Variable: 2)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function payback(
        address token,
        uint amt,
        uint rateMode,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        bool isEth = token == ethAddr;
        address _token = isEth ? wethAddr : token;

        TokenInterface tokenContract = TokenInterface(_token);

        _amt = _amt == uint(-1) ? getPaybackBalance(_token, rateMode) : _amt;

        if (isEth) convertEthToWeth(isEth, tokenContract, _amt);

        tokenContract.approve(address(aave), _amt);

        aave.repay(_token, _amt, rateMode, address(this));

        setUint(setId, _amt);

        _eventName = "LogPayback(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, rateMode, getId, setId);
    }

    /**
     * @dev Enable collateral
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
            if (getCollateralBalance(token) > 0 && !getIsColl(token)) {
                aave.setUserUseReserveAsCollateral(token, true);
            }
        }

        _eventName = "LogEnableCollateral(address[]);";
        _eventParam = abi.encode(tokens);
    }
}

contract ConnectAave is AaveResolver {
    string public name = "AaveV2-v1.1";
}
