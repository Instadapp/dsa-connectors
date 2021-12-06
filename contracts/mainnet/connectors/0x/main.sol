pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title 0x.
 * @dev On-chain DEX Aggregator.
 */

import {TokenInterface, MemoryInterface} from "../../common/interfaces.sol";
import {Stores} from "../../common/stores.sol";
import {ZeroExData, zeroExInterface} from "./interface.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

contract zeroExHelper is Helpers {
    function zeroExSwap(ZeroExData memory zeroExData, uint256 ethAmt)
        internal
        returns (uint256 buyAmt)
    {
        TokenInterface buyToken = zeroExData.buyToken;
        (uint256 _buyDec, uint256 _sellDec) = getTokensDec(
            buyToken,
            zeroExData.sellToken
        );
        uint256 _sellAmt18 = convertTo18(_sellDec, zeroExData._sellAmt);
        uint256 _slippageAmt = convert18ToDec(
            _buyDec,
            wmul(zeroExData.unitAmt, _sellAmt18)
        );

        uint256 initalBal = getTokenBal(buyToken);

        // solium-disable-next-line security/no-call-value
        (bool success, ) = zeroExAddr.call{value: ethAmt}(zeroExData.callData);
        if (!success) revert("0x-swap-failed");

        uint256 finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    function _swap(ZeroExData memory zeroExData, uint256 setId)
        internal
        returns (ZeroExData memory)
    {
        TokenInterface _sellAddr = zeroExData.sellToken;

        uint256 ethAmt;
        if (address(_sellAddr) == ethAddr) {
            ethAmt = zeroExData._sellAmt;
        } else {
            address transformWallet = address(
                zeroExInterface(zeroExAddr).getTransformWallet()
            );
            approve(
                TokenInterface(_sellAddr),
                transformWallet,
                zeroExData._sellAmt
            );
        }

        zeroExData._buyAmt = zeroExSwap(zeroExData, ethAmt);
        setUint(setId, zeroExData._buyAmt);

        return zeroExData;
    }
}

abstract contract ZeroEx is zeroExHelper {
    /**
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

contract ConnectV2ZeroEx is ZeroEx {
    string public name = "";
}
