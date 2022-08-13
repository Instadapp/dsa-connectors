//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title 0x.
 * @dev On-chain DEX Aggregator.
 */

import {TokenInterface, MemoryInterface} from "../../common/interfaces.sol";
import {Stores} from "../../common/stores.sol";
import {ZeroExData} from "./interface.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

abstract contract ZeroEx is Helpers {
    /**
     * @notice Swap tokens on 0x
     * @dev Sell ETH/ERC20_Token using 0x.
     * @param buyAddr The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt The amount of the token to sell.
     * @param unitAmt The amount of buyAmt/sellAmt with slippage.
     * @param callData Data from 0x API.
     * @param setId ID stores the amount of token brought.
     */
    function swap(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 unitAmt,
        bytes calldata callData,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        ZeroExData memory zeroExData = ZeroExData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            unitAmt: unitAmt,
            callData: callData,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        zeroExData = _swap(zeroExData, setId);

        _eventName = "LogSwap(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            buyAddr,
            sellAddr,
            zeroExData._buyAmt,
            zeroExData._sellAmt,
            0,
            setId
        );
    }
}

contract ConnectV2ZeroExOptimism is ZeroEx {
    string public name = "0x-V4";
}
