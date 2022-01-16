pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title UniswapV3_autoRouter.
 * @dev DEX.
 */

// import files from common directory
import { TokenInterface , MemoryInterface } from "../../../common/interfaces.sol";
import { Stores } from "../../../common/stores.sol";
import { SwapData } from "./interface.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract AutoRouter is Helpers, Events {
    /**
     * @dev Sell ETH/ERC20_Token using uniswap v3 auto router.
     * @notice Swap tokens from getting an optimized trade routes
     * @param buyAddr The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt The amount of the token to sell.
     * @param unitAmt The amount of buyAmt/sellAmt with slippage.
     * @param callData Data from Uniswap V3 auto router SDK.
     * @param setId ID stores the amount of token brought.
    */
    function sell(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        bytes calldata callData,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        SwapData memory swapData = SwapData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            unitAmt: unitAmt,
            callData: callData,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        swapData = _swap(swapData, setId);

        _eventName = "LogSwap(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(buyAddr, sellAddr, swapData._buyAmt, swapData._sellAmt, 0, setId);
    }
}

contract ConnectV2UniswapV3AutoRouter is AutoRouter {
    string public name = "UniswapV3-Auto-Router-v1";
}
