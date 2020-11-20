pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface LiqudityInterface {
    function deposit(address, uint) external payable;
    function withdraw(address, uint) external;

    function accessLiquidity(address[] calldata, uint[] calldata) external;
    function returnLiquidity(address[] calldata) external payable;

    function isTknAllowed(address) external view returns(bool);
    function tknToCTkn(address) external view returns(address);
    function liquidityBalance(address, address) external view returns(uint);

    function borrowedToken(address) external view returns(uint);
}

interface InstaPoolFeeInterface {
    function fee() external view returns(uint);
    function feeCollector() external view returns(address);
}

interface CTokenInterface {
    function borrowBalanceCurrent(address account) external returns (uint);
    function balanceOf(address owner) external view returns (uint256 balance);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint); // For ERC20
}

interface CETHInterface {
    function borrowBalanceCurrent(address account) external returns (uint);
    function repayBorrowBehalf(address borrower) external payable;
}


interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface MemoryInterface {
    function getUint(uint _id) external returns (uint _num);
    function setUint(uint _id, uint _val) external;
}

interface EventInterface {
    function emitEvent(uint _connectorType, uint _connectorID, bytes32 _eventCode, bytes calldata _eventData) external;
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
}

contract Helpers is DSMath {

    using SafeERC20 for IERC20;

    /**
     * @dev Return ethereum address
     */
    function getAddressETH() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev Return Memory Variable Address
     */
    function getMemoryAddr() internal pure returns (address) {
        return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F; // InstaMemory Address
    }

    /**
     * @dev Return InstaEvent Address.
     */
    function getEventAddr() internal pure returns (address) {
        return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97; // InstaEvent Address
    }

    /**
     * @dev Get Uint value from InstaMemory Contract.
    */
    function getUint(uint getId, uint val) internal returns (uint returnVal) {
        returnVal = getId == 0 ? val : MemoryInterface(getMemoryAddr()).getUint(getId);
    }

    /**
     * @dev Set Uint value in InstaMemory Contract.
    */
    function setUint(uint setId, uint val) internal {
        if (setId != 0) MemoryInterface(getMemoryAddr()).setUint(setId, val);
    }

    /**
     * @dev Connector Details.
    */
    function connectorID() public pure returns(uint _type, uint _id) {
        (_type, _id) = (1, 33);
    }

    function _transfer(address payable to, IERC20 token, uint _amt) internal {
        address(token) == getAddressETH() ?
            to.transfer(_amt) :
            token.safeTransfer(to, _amt);
    }

    function _getBalance(IERC20 token) internal view returns (uint256) {
        return address(token) == getAddressETH() ?
            address(this).balance :
            token.balanceOf(address(this));
    }
}


contract LiquidityHelpers is Helpers {
    /**
     * @dev Return InstaPool address
     */
    function getLiquidityAddress() internal pure returns (address) {
        return 0x06cB7C24990cBE6b9F99982f975f9147c000fec6;
    }

    /**
     * @dev Return InstaPoolFee address
     */
    function getInstaPoolFeeAddr() internal pure returns (address) {
        return 0xAaA91046C1D1a210017e36394C83bD5070dadDa5;
    }

    function calculateTotalFeeAmt(IERC20 token, uint amt) internal view returns (uint totalAmt) {
        uint fee = InstaPoolFeeInterface(getInstaPoolFeeAddr()).fee();
        uint flashAmt = LiqudityInterface(getLiquidityAddress()).borrowedToken(address(token));
        if (fee == 0) {
            totalAmt = amt;
        } else {
            uint feeAmt = wmul(flashAmt, fee);
            totalAmt = add(amt, feeAmt);
        }
    }

    function calculateFeeAmt(IERC20 token, uint amt) internal view returns (address feeCollector, uint feeAmt) {
        InstaPoolFeeInterface feeContract = InstaPoolFeeInterface(getInstaPoolFeeAddr());
        uint fee = feeContract.fee();
        feeCollector = feeContract.feeCollector();
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


contract LiquidityManage is LiquidityHelpers {

    event LogDepositLiquidity(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdrawLiquidity(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);

    /**
     * @dev Deposit Liquidity in InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        uint ethAmt;
        if (token == getAddressETH()) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            ethAmt = _amt;
        } else {
            IERC20 tokenContract = IERC20(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(getLiquidityAddress(), _amt);
        }

        LiqudityInterface(getLiquidityAddress()).deposit.value(ethAmt)(token, _amt);
        setUint(setId, _amt);

        emit LogDepositLiquidity(token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogDepositLiquidity(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Withdraw Liquidity in InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdraw(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        LiqudityInterface(getLiquidityAddress()).withdraw(token, _amt);
        setUint(setId, _amt);

        emit LogWithdrawLiquidity(token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogWithdrawLiquidity(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }
}

contract EventHelpers is LiquidityManage {
    event LogFlashBorrow(
        address indexed token,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogFlashPayback(
        address indexed token,
        uint256 tokenAmt,
        uint256 feeCollected,
        uint256 getId,
        uint256 setId
    );

    event LogOriginFeeCollected(
        address indexed origin,
        address indexed token,
        uint256 tokenAmt,
        uint256 originFeeAmt
    );

    function emitFlashBorrow(address token, uint256 tokenAmt, uint256 getId, uint256 setId) internal {
        emit LogFlashBorrow(token, tokenAmt, getId, setId);
        bytes32 _eventCode = keccak256("LogFlashBorrow(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, tokenAmt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    function emitFlashPayback(address token, uint256 tokenAmt, uint256 feeCollected, uint256 getId, uint256 setId) internal {
        emit LogFlashPayback(token, tokenAmt, feeCollected, getId, setId);
        bytes32 _eventCode = keccak256("LogFlashPayback(address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, tokenAmt, feeCollected, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    function emitOriginFeeCollected(address origin, address token, uint256 tokenAmt, uint256 originFeeAmt) internal {
        emit LogOriginFeeCollected(origin, token, tokenAmt, originFeeAmt);
        bytes32 _eventCodeOrigin = keccak256("LogOriginFeeCollected(address,address,uint256,uint256)");
        bytes memory _eventParamOrigin = abi.encode(origin, token, tokenAmt, originFeeAmt);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCodeOrigin, _eventParamOrigin);
    }
}

contract LiquidityAccessHelper is EventHelpers {
    /**
     * @dev Add Fee Amount to borrowed flashloan/
     * @param amt Get token amount at this ID from `InstaMemory` Contract.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function addFeeAmount(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);
        require(_amt != 0, "amt-is-0");
        uint totalFee = calculateTotalFeeAmt(IERC20(token), _amt);

        setUint(setId, totalFee);
    }

}

contract LiquidityAccess is LiquidityAccessHelper {
    /**
     * @dev Access Token Liquidity from InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function flashBorrow(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        address[] memory _tknAddrs = new address[](1);
        _tknAddrs[0] = token;
        uint[] memory _amts = new uint[](1);
        _amts[0] = _amt;

        LiqudityInterface(getLiquidityAddress()).accessLiquidity(_tknAddrs, _amts);

        setUint(setId, _amt);
        emitFlashBorrow(token, _amt, getId, setId);
    }

    /**
     * @dev Return Token Liquidity from InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function flashPayback(address token, uint getId, uint setId) external payable {
        LiqudityInterface liquidityContract = LiqudityInterface(getLiquidityAddress());
        uint _amt = liquidityContract.borrowedToken(token);
        IERC20 tokenContract = IERC20(token);

        (address feeCollector, uint feeAmt) = calculateFeeAmt(tokenContract, _amt);

        address[] memory _tknAddrs = new address[](1);
        _tknAddrs[0] = token;

        _transfer(payable(address(liquidityContract)), tokenContract, _amt);
        liquidityContract.returnLiquidity(_tknAddrs);

        if (feeAmt > 0) _transfer(payable(feeCollector), tokenContract, feeAmt);

        setUint(setId, _amt);
        emitFlashPayback(token, _amt, feeAmt, getId, setId);
    }

    /**
     * @dev Return Token Liquidity from InstaPool and Transfer 20% of Collected Fee to `origin`.
     * @param origin origin address to transfer 20% of the collected fee.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function flashPaybackOrigin(address origin, address token, uint getId, uint setId) external payable {
        require(origin != address(0), "origin-is-address(0)");
        LiqudityInterface liquidityContract = LiqudityInterface(getLiquidityAddress());
        uint _amt = liquidityContract.borrowedToken(token);
        IERC20 tokenContract = IERC20(token);

        (address feeCollector, uint poolFeeAmt, uint originFeeAmt) = calculateFeeAmtOrigin(tokenContract, _amt);

        address[] memory _tknAddrs = new address[](1);
        _tknAddrs[0] = token;

        _transfer(payable(address(liquidityContract)), tokenContract, _amt);
        liquidityContract.returnLiquidity(_tknAddrs);

        if (poolFeeAmt > 0) {
            _transfer(payable(feeCollector), tokenContract, poolFeeAmt);
            _transfer(payable(origin), tokenContract, originFeeAmt);
        }

        setUint(setId, _amt);

        emitFlashPayback(token, _amt, poolFeeAmt, getId, setId);
        emitOriginFeeCollected(origin, token, _amt, originFeeAmt);
    }
}

contract LiquidityAccessMulti is LiquidityAccess {
    /**
     * @dev Access Multiple Token liquidity from InstaPool.
     * @param tokens Array of token addresses.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amts Array of token amount.
     * @param getId get token amounts at this IDs from `InstaMemory` Contract.
     * @param setId set token amounts at this IDs in `InstaMemory` Contract.
    */
    function flashMultiBorrow(
        address[] calldata tokens,
        uint[] calldata amts,
        uint[] calldata getId,
        uint[] calldata setId
    ) external payable {
        uint _length = tokens.length;
        uint[] memory _amts = new uint[](_length);
        for (uint i = 0; i < _length; i++) {
            _amts[i] = getUint(getId[i], amts[i]);
        }

        LiqudityInterface(getLiquidityAddress()).accessLiquidity(tokens, _amts);

        for (uint i = 0; i < _length; i++) {
            setUint(setId[i], _amts[i]);
            emitFlashBorrow(tokens[i], _amts[i], getId[i], setId[i]);
        }
    }

    /**
     * @dev Return Multiple token liquidity from InstaPool.
     * @param tokens Array of token addresses.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param getId get token amounts at this IDs from `InstaMemory` Contract.
     * @param setId set token amounts at this IDs in `InstaMemory` Contract.
    */
    function flashMultiPayback(address[] calldata tokens, uint[] calldata getId, uint[] calldata setId) external payable {
        LiqudityInterface liquidityContract = LiqudityInterface(getLiquidityAddress());

        uint _length = tokens.length;

        for (uint i = 0; i < _length; i++) {
            uint _amt = liquidityContract.borrowedToken(tokens[i]);
            IERC20 tokenContract = IERC20(tokens[i]);
            (address feeCollector, uint feeAmt) = calculateFeeAmt(tokenContract, _amt);

            _transfer(payable(address(liquidityContract)), tokenContract, _amt);

            if (feeAmt > 0) _transfer(payable(feeCollector), tokenContract, feeAmt);

            setUint(setId[i], _amt);

            emitFlashPayback(tokens[i], _amt, feeAmt, getId[i], setId[i]);
        }

        liquidityContract.returnLiquidity(tokens);
    }

    /**
     * @dev Return Multiple token liquidity from InstaPool and Tranfer 20% of the Fee to Origin.
     * @param tokens Array of token addresses.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param getId get token amounts at this IDs from `InstaMemory` Contract.
     * @param setId set token amounts at this IDs in `InstaMemory` Contract.
    */
    function flashMultiPaybackOrigin(address origin, address[] calldata tokens, uint[] calldata getId, uint[] calldata setId) external payable {
        LiqudityInterface liquidityContract = LiqudityInterface(getLiquidityAddress());

        uint _length = tokens.length;

        for (uint i = 0; i < _length; i++) {
            uint _amt = liquidityContract.borrowedToken(tokens[i]);
            IERC20 tokenContract = IERC20(tokens[i]);

            (address feeCollector, uint poolFeeAmt, uint originFeeAmt) = calculateFeeAmtOrigin(tokenContract, _amt);

           _transfer(payable(address(liquidityContract)), tokenContract, _amt);

            if (poolFeeAmt > 0) {
                _transfer(payable(feeCollector), tokenContract, poolFeeAmt);
                _transfer(payable(origin), tokenContract, originFeeAmt);
            }

            setUint(setId[i], _amt);

            emitFlashPayback(tokens[i], _amt, poolFeeAmt,  getId[i], setId[i]);
            emitOriginFeeCollected(origin, tokens[i], _amt, originFeeAmt);
        }
        liquidityContract.returnLiquidity(tokens);
    }
}

contract ConnectInstaPool is LiquidityAccessMulti {
    string public name = "InstaPool-v2.1";
}
