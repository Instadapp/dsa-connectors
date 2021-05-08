pragma solidity ^0.7.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { TokenInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract LiquidityManage is Helpers, Events {
    /**
     * @dev Deposit Liquidity in InstaPool.
     * @notice Deposit Liquidity in InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
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

        uint ethAmt;
        if (token == ethAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            ethAmt = _amt;
        } else {
            IERC20 tokenContract = IERC20(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(address(instaPool), _amt);
        }

        instaPool.deposit{value: ethAmt}(token, _amt);
        setUint(setId, _amt);

        _eventName = "LogDepositLiquidity(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, getId, setId);
    }

    /**
     * @dev Withdraw Liquidity from InstaPool.
     * @notice Withdraw Liquidity from InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
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

        instaPool.withdraw(token, _amt);
        setUint(setId, _amt);

        _eventName = "LogWithdrawLiquidity(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, getId, setId);
    }
}

abstract contract LiquidityAccessHelper is LiquidityManage {
    /**
     * @dev Add Fee Amount to borrowed flashloan.
     * @notice Add Fee Amount to borrowed flashloan.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
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
     * @notice Take flashloan from InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function flashBorrow(
        address token,
        uint amt,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        address[] memory _tknAddrs = new address[](1);
        _tknAddrs[0] = token;
        uint[] memory _amts = new uint[](1);
        _amts[0] = _amt;

        instaPool.accessLiquidity(_tknAddrs, _amts);

        setUint(setId, _amt);
        
        _eventName = "LogFlashBorrow(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, getId, setId);
    }

    /**
     * @dev Return Token Liquidity from InstaPool.
     * @notice Payback borrowed flashloan to InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function flashPayback(
        address token,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = instaPool.borrowedToken(token);
        IERC20 tokenContract = IERC20(token);

        (address feeCollector, uint feeAmt) = calculateFeeAmt(tokenContract, _amt);

        address[] memory _tknAddrs = new address[](1);
        _tknAddrs[0] = token;

        _transfer(payable(address(instaPool)), tokenContract, _amt);
        instaPool.returnLiquidity(_tknAddrs);

        if (feeAmt > 0) _transfer(payable(feeCollector), tokenContract, feeAmt);

        setUint(setId, _amt);

        _eventName = "LogFlashPayback(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, feeAmt, getId, setId);
    }

    /**
     * @dev Return Token Liquidity from InstaPool and Transfer 20% of Collected Fee to `origin`.
     * @notice Payback borrowed flashloan to InstaPool and Transfer 20% of Collected Fee to `origin`.
     * @param origin origin address to transfer 20% of the collected fee.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function flashPaybackOrigin(
        address origin,
        address token,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(origin != address(0), "origin-is-address(0)");
        uint _amt = instaPool.borrowedToken(token);
        IERC20 tokenContract = IERC20(token);

        (address feeCollector, uint poolFeeAmt, uint originFeeAmt) = calculateFeeAmtOrigin(tokenContract, _amt);

        address[] memory _tknAddrs = new address[](1);
        _tknAddrs[0] = token;

        _transfer(payable(address(instaPool)), tokenContract, _amt);
        instaPool.returnLiquidity(_tknAddrs);

        if (poolFeeAmt > 0) {
            _transfer(payable(feeCollector), tokenContract, poolFeeAmt);
            _transfer(payable(origin), tokenContract, originFeeAmt);
        }

        setUint(setId, _amt);

        _eventName = "LogFlashPaybackOrigin(address,address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(origin, token, _amt, poolFeeAmt, originFeeAmt, getId, setId);
    }
}

contract LiquidityAccessMulti is LiquidityAccess {
    /**
     * @dev Access Multiple Token liquidity from InstaPool.
     * @notice Take multiple tokens flashloan from Instapool.
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
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _length = tokens.length;
        uint[] memory _amts = new uint[](_length);
        for (uint i = 0; i < _length; i++) {
            _amts[i] = getUint(getId[i], amts[i]);
        }

        instaPool.accessLiquidity(tokens, _amts);

        for (uint i = 0; i < _length; i++) {
            setUint(setId[i], _amts[i]);
        }

        _eventName = "LogMultiBorrow(address[],uint256[],uint256[],uint256[])";
        _eventParam = abi.encode(tokens, amts, getId, setId);
    }

    /**
     * @dev Return Multiple token liquidity from InstaPool.
     * @notice Payback borrowed multiple tokens flashloan to Instapool.
     * @param tokens Array of token addresses.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param getId get token amounts at this IDs from `InstaMemory` Contract.
     * @param setId set token amounts at this IDs in `InstaMemory` Contract.
    */
    function flashMultiPayback(
        address[] calldata tokens,
        uint[] calldata getId,
        uint[] calldata setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _length = tokens.length;

        for (uint i = 0; i < _length; i++) {
            uint _amt = instaPool.borrowedToken(tokens[i]);
            IERC20 tokenContract = IERC20(tokens[i]);
            (address feeCollector, uint feeAmt) = calculateFeeAmt(tokenContract, _amt);

            _transfer(payable(address(instaPool)), tokenContract, _amt);

            if (feeAmt > 0) _transfer(payable(feeCollector), tokenContract, feeAmt);

            setUint(setId[i], _amt);
        }

        instaPool.returnLiquidity(tokens);

        _eventName = "LogMultiPayback(address[],uint256[],uint256[])";
        _eventParam = abi.encode(tokens, getId, setId);
    }

    // TODO - Fix stack too deep
    // /**
    //  * @dev Return Multiple token liquidity from InstaPool and Tranfer 20% of the Fee to Origin.
    //  * @param tokens Array of token addresses.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
    //  * @param getId get token amounts at this IDs from `InstaMemory` Contract.
    //  * @param setId set token amounts at this IDs in `InstaMemory` Contract.
    // */
    // function flashMultiPaybackOrigin(
    //     address origin,
    //     address[] calldata tokens,
    //     uint[] calldata getId,
    //     uint[] calldata setId
    // ) external payable returns (string memory _eventName, bytes memory _eventParam) {
    //     uint _length = tokens.length;

    //     for (uint i = 0; i < _length; i++) {
    //         uint _amt = instaPool.borrowedToken(tokens[i]);
    //         IERC20 tokenContract = IERC20(tokens[i]);

    //         (address feeCollector, uint poolFeeAmt, uint originFeeAmt) = calculateFeeAmtOrigin(tokenContract, _amt);

    //        _transfer(payable(address(instaPool)), tokenContract, _amt);

    //         if (poolFeeAmt > 0) {
    //             _transfer(payable(feeCollector), tokenContract, poolFeeAmt);
    //             _transfer(payable(origin), tokenContract, originFeeAmt);
    //         }

    //         setUint(setId[i], _amt);
    //     }
    //     instaPool.returnLiquidity(tokens);

    //     _eventName = "LogMultiPaybackOrigin(address,address[],uint256[],uint256[])";
    //     _eventParam = abi.encode(origin, tokens, getId, setId);
    // }
}

contract ConnectV2InstaPool is LiquidityAccessMulti {
    string public name = "InstaPool-v2";
}
