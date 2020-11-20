pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

interface AaveInterface {
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external payable;
    function redeemUnderlying(
        address _reserve,
        address payable _user,
        uint256 _amount,
        uint256 _aTokenBalanceAfterRedeem
    ) external;
    function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external;
    function getUserReserveData(address _reserve, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentBorrowBalance,
        uint256 principalBorrowBalance,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint256 liquidityRate,
        uint256 originationFee,
        uint256 variableBorrowIndex,
        uint256 lastUpdateTimestamp,
        bool usageAsCollateralEnabled
    );
    function borrow(address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode) external;
    function repay(address _reserve, uint256 _amount, address payable _onBehalfOf) external payable;
}

interface AaveProviderInterface {
    function getLendingPool() external view returns (address);
    function getLendingPoolCore() external view returns (address);
}

interface AaveCoreInterface {
    function getReserveATokenAddress(address _reserve) external view returns (address);
}

interface ATokenInterface {
    function redeem(uint256 _amount) external;
    function balanceOf(address _user) external view returns(uint256);
    function principalBalanceOf(address _user) external view returns(uint256);
}

contract AaveHelpers is DSMath, Stores {

    /**
     * @dev get Aave Provider
    */
    function getAaveProvider() internal pure returns (AaveProviderInterface) {
        return AaveProviderInterface(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8); //mainnet
        // return AaveProviderInterface(0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5); //kovan
    }

    /**
     * @dev get Referral Code
    */
    function getReferralCode() internal pure returns (uint16) {
        return 3228;
    }

    function getIsColl(AaveInterface aave, address token) internal view returns (bool isCol) {
        (, , , , , , , , , isCol) = aave.getUserReserveData(token, address(this));
    }

    function getWithdrawBalance(address token) internal view returns (uint bal) {
        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());
        (bal, , , , , , , , , ) = aave.getUserReserveData(token, address(this));
    }

    function getPaybackBalance(AaveInterface aave, address token) internal view returns (uint bal, uint fee) {
        (, bal, , , , , fee, , , ) = aave.getUserReserveData(token, address(this));
    }
}


contract BasicResolver is AaveHelpers {
    event LogDeposit(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdraw(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogBorrow(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogPayback(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);

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

        emit LogDeposit(token, _amt, getId, setId);
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

        emit LogWithdraw(token, _amt, getId, setId);
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

        emit LogBorrow(token, _amt, getId, setId);
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

        emit LogPayback(token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogPayback(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }
}

contract ConnectAave is BasicResolver {
    string public name = "Aave-v1";
}