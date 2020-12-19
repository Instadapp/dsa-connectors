pragma solidity ^0.6.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { AaveInterface, AaveProviderInterface, AaveCoreInterface, ATokenInterface } from "./interface.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

contract BasicResolver is Helpers, Events {
    /**
     * @dev Deposit ETH/ERC20_Token.
     * @param token token address to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to deposit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);
        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());

        uint ethAmt;
        if (token == getEthAddr()) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            ethAmt = _amt;
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(getAaveProvider().getLendingPoolCore(), _amt);
        }

        aave.deposit.value(ethAmt)(token, _amt, getReferralCode());

        if (!getIsColl(aave, token)) aave.setUserUseReserveAsCollateral(token, true);

        setUint(setId, _amt);

        emitLogDeposit(token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogDeposit(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @param token token address to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdraw(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);
        AaveCoreInterface aaveCore = AaveCoreInterface(getAaveProvider().getLendingPoolCore());
        ATokenInterface atoken = ATokenInterface(aaveCore.getReserveATokenAddress(token));
        TokenInterface tokenContract = TokenInterface(token);

        uint initialBal = token == getEthAddr() ? address(this).balance : tokenContract.balanceOf(address(this));
        atoken.redeem(_amt);
        uint finalBal = token == getEthAddr() ? address(this).balance : tokenContract.balanceOf(address(this));

        _amt = sub(finalBal, initialBal);
        setUint(setId, _amt);

        emitLogWithdraw(token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogWithdraw(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @param token token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to borrow.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function borrow(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);
        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());
        aave.borrow(token, _amt, 2, getReferralCode());
        setUint(setId, _amt);

        emitLogBorrow(token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogBorrow(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @param token token address to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to payback.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function payback(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);
        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());

        if (_amt == uint(-1)) {
            uint fee;
            (_amt, fee) = getPaybackBalance(aave, token);
            _amt = add(_amt, fee);
        }
        uint ethAmt;
        if (token == getEthAddr()) {
            ethAmt = _amt;
        } else {
            TokenInterface(token).approve(getAaveProvider().getLendingPoolCore(), _amt);
        }

        aave.repay.value(ethAmt)(token, _amt, payable(address(this)));

        setUint(setId, _amt);

        emitLogPayback(token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogPayback(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }
}

contract ConnectAave is BasicResolver {
    string public name = "Aave-v1";
}