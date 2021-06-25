pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title 1Inch(On-chain).
 * @dev On-chain and off-chian DEX Aggregator.
 */

import { TokenInterface , MemoryInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { OneProtoInterface, OneProtoData, OneProtoMultiData } from "./interface.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract OneProtoResolver is Helpers, Events {
    /**
     * @dev 1proto contract swap handler
     * @param oneProtoData - Struct with swap data defined in interfaces.sol 
     */
    function oneProtoSwap(
        OneProtoData memory oneProtoData
    ) internal returns (uint buyAmt) {
        TokenInterface _sellAddr = oneProtoData.sellToken;
        TokenInterface _buyAddr = oneProtoData.buyToken;
        uint _sellAmt = oneProtoData._sellAmt;

        uint _slippageAmt = getSlippageAmt(_buyAddr, _sellAddr, _sellAmt, oneProtoData.unitAmt);

        uint ethAmt;
        if (address(_sellAddr) == ethAddr) {
            ethAmt = _sellAmt;
        } else {
            approve(_sellAddr, address(oneProto), _sellAmt);
        }


        uint initalBal = getTokenBal(_buyAddr);
        oneProto.swap{value: ethAmt}(
            _sellAddr,
            _buyAddr,
            _sellAmt,
            _slippageAmt,
            oneProtoData.distribution,
            oneProtoData.disableDexes
        );
        uint finalBal = getTokenBal(_buyAddr);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    /**
     * @dev 1proto contract multi swap handler
     * @param oneProtoData - Struct with multiple swap data defined in interfaces.sol 
     */
    function oneProtoSwapMulti(OneProtoMultiData memory oneProtoData) internal returns (uint buyAmt) {
        TokenInterface _sellAddr = oneProtoData.sellToken;
        TokenInterface _buyAddr = oneProtoData.buyToken;
        uint _sellAmt = oneProtoData._sellAmt;
        uint _slippageAmt = getSlippageAmt(_buyAddr, _sellAddr, _sellAmt, oneProtoData.unitAmt);

        uint ethAmt;
        if (address(_sellAddr) == ethAddr) {
            ethAmt = _sellAmt;
        } else {
            approve(_sellAddr, address(oneProto), _sellAmt);
        }

        uint initalBal = getTokenBal(_buyAddr);
        oneProto.swapMulti{value: ethAmt}(
            convertToTokenInterface(oneProtoData.tokens),
            _sellAmt,
            _slippageAmt,
            oneProtoData.distribution,
            oneProtoData.disableDexes
        );
        uint finalBal = getTokenBal(_buyAddr);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }
}

abstract contract OneProtoResolverHelpers is OneProtoResolver {
    /**
     * @dev Gets the swapping data offchian for swaps and calls swap.
     * @param oneProtoData - Struct with swap data defined in interfaces.sol 
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
     */
    function _sell(
        OneProtoData memory oneProtoData,
        uint getId,
        uint setId
    ) internal returns (OneProtoData memory) {
        uint _sellAmt = getUint(getId, oneProtoData._sellAmt);

        oneProtoData._sellAmt = _sellAmt == uint(-1) ?
            getTokenBal(oneProtoData.sellToken) :
            _sellAmt;

        oneProtoData._buyAmt = oneProtoSwap(oneProtoData);

        setUint(setId, oneProtoData._buyAmt);
        
        return oneProtoData;
    }

    /**
     * @dev Gets the swapping data offchian for swaps and calls swap.
     * @param oneProtoData - Struct with multiple swap data defined in interfaces.sol 
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
     */
    function _sellMulti(
        OneProtoMultiData memory oneProtoData,
        uint getId,
        uint setId
    ) internal returns (OneProtoMultiData memory) {
        uint _sellAmt = getUint(getId, oneProtoData._sellAmt);

        oneProtoData._sellAmt = _sellAmt == uint(-1) ?
            getTokenBal(oneProtoData.sellToken) :
            _sellAmt;

        oneProtoData._buyAmt = oneProtoSwapMulti(oneProtoData);
        setUint(setId, oneProtoData._buyAmt);

        // emitLogSellMulti(oneProtoData, getId, setId);

        return oneProtoData;
    }
}

abstract contract OneProto is OneProtoResolverHelpers {
    /**
     * @dev Sell ETH/ERC20_Token using 1Proto using off-chain calculation.
     * @notice Swap tokens from exchanges like Uniswap, Kyber etc, with calculation done off-chain.
     * @param buyAddr The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt The amount of the token to sell.
     * @param unitAmt The amount of buyAmt/sellAmt with slippage.
     * @param distribution The distribution of swap across different DEXs.
     * @param disableDexes Disable a dex. (To disable none: 0)
     * @param getId ID to retrieve sellAmt.
     * @param setId ID stores the amount of token brought.
    */
    function sell(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        uint[] calldata distribution,
        uint disableDexes,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        OneProtoData memory oneProtoData = OneProtoData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            _sellAmt: sellAmt,
            unitAmt: unitAmt,
            distribution: distribution,
            disableDexes: disableDexes,
            _buyAmt: 0
        });

        oneProtoData = _sell(oneProtoData, getId, setId);

        _eventName = "LogSell(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(buyAddr, sellAddr, oneProtoData._buyAmt, oneProtoData._sellAmt, getId, setId);
    }

    /**
     * @dev Sell Multiple tokens using 1proto using off-chain calculation.
     * @notice Swap multiple tokens from exchanges like Uniswap, Kyber etc, with calculation done off-chain.
     * @param tokens Array of tokens.
     * @param sellAmt The amount of the token to sell.
     * @param unitAmt The amount of buyAmt/sellAmt with slippage.
     * @param distribution The distribution of swap across different DEXs.
     * @param disableDexes Disable a dex. (To disable none: 0)
     * @param getId ID to retrieve sellAmt.
     * @param setId ID stores the amount of token brought.
    */
    function sellMulti(
        address[] calldata tokens,
        uint sellAmt,
        uint unitAmt,
        uint[] calldata distribution,
        uint[] calldata disableDexes,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _length = tokens.length;
        OneProtoMultiData memory oneProtoData = OneProtoMultiData({
            tokens: tokens,
            buyToken: TokenInterface(address(tokens[_length - 1])),
            sellToken: TokenInterface(address(tokens[0])),
            unitAmt: unitAmt,
            distribution: distribution,
            disableDexes: disableDexes,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        oneProtoData = _sellMulti(oneProtoData, getId, setId);

        _eventName = "LogSellMulti(address[],address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            tokens,
            address(oneProtoData.buyToken),
            address(oneProtoData.sellToken),
            oneProtoData._buyAmt,
            oneProtoData._sellAmt,
            getId,
            setId
        );
    }
}

contract ConnectV2OneProto is OneProto {
    string public name = "1Proto-v1.1";
}
