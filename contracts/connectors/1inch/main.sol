pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// import files from common directory
import { TokenInterface , MemoryInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { OneInchInterace, OneProtoInterface, OneProtoMappingInterface, OneProtoData, OneProtoMultiData, OneInchData } from "./interface.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";


abstract contract OneProtoResolver is Helpers, Events {

    /**
     * @dev 1proto contract swap handler
     * @param oneProtoContract - 1 proto contract
     * @param oneProtoData - Struct with swap data defined in interfaces.sol 
     */
    function oneProtoSwap(
        OneProtoInterface oneProtoContract,
        OneProtoData memory oneProtoData
    ) internal returns (uint buyAmt) {
        TokenInterface _sellAddr = oneProtoData.sellToken;
        TokenInterface _buyAddr = oneProtoData.buyToken;
        uint _sellAmt = oneProtoData._sellAmt;

        uint _slippageAmt = getSlippageAmt(_buyAddr, _sellAddr, _sellAmt, oneProtoData.unitAmt);

        uint ethAmt;
        if (address(_sellAddr) == getEthAddr()) {
            ethAmt = _sellAmt;
        } else {
            _sellAddr.approve(address(oneProtoContract), _sellAmt);
        }


        uint initalBal = getTokenBal(_buyAddr);
        oneProtoContract.swap{value: ethAmt}(
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

        OneProtoInterface oneSplitContract = OneProtoInterface(getOneProtoAddress());
        uint ethAmt;
        if (address(_sellAddr) == getEthAddr()) {
            ethAmt = _sellAmt;
        } else {
            _sellAddr.approve(address(oneSplitContract), _sellAmt);
        }

        uint initalBal = getTokenBal(_buyAddr);
        oneSplitContract.swapMulti{value: ethAmt}(
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

abstract contract OneInchResolver is OneProtoResolver {
    /**
     * @dev 1inch swap uses `.call()`. This function restrict it to call only swap/trade functionality
     * @param callData - calldata to extract the first 4 bytes for checking function signature
     */
    function checkOneInchSig(bytes memory callData) internal pure returns(bool isOk) {
        bytes memory _data = callData;
        bytes4 sig;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            sig := mload(add(_data, 32))
        }
        isOk = sig == getOneInchSig();
    }

    /**
     * @dev 1inch API swap handler
     * @param oneInchData - contains data returned from 1inch API. Struct defined in interfaces.sol
     * @param ethAmt - Eth to swap for .value()
     */
    function oneInchSwap(
        OneInchData memory oneInchData,
        uint ethAmt
    ) internal returns (uint buyAmt) {
        TokenInterface buyToken = oneInchData.buyToken;
        (uint _buyDec, uint _sellDec) = getTokensDec(buyToken, oneInchData.sellToken);
        uint _sellAmt18 = convertTo18(_sellDec, oneInchData._sellAmt);
        uint _slippageAmt = convert18ToDec(_buyDec, wmul(oneInchData.unitAmt, _sellAmt18));

        uint initalBal = getTokenBal(buyToken);

        // solium-disable-next-line security/no-call-value
        (bool success, ) = address(getOneInchAddress()).call{value: ethAmt}(oneInchData.callData);
        if (!success) revert("1Inch-swap-failed");

        uint finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

}

abstract contract OneProtoResolverHelpers is OneInchResolver {

    /**
     * @dev Gets the swapping data onchain for swaps and calls swap.
     * @param oneProtoData - Struct with swap data defined in interfaces.sol 
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
     */
    function _sell(
        OneProtoData memory oneProtoData,
        uint256 getId,
        uint256 setId
    ) internal {
        uint _sellAmt = getUint(getId, oneProtoData._sellAmt);

        oneProtoData._sellAmt = _sellAmt == uint(-1) ?
            getTokenBal(oneProtoData.sellToken) :
            _sellAmt;

        OneProtoInterface oneProtoContract = OneProtoInterface(getOneProtoAddress());

        (, oneProtoData.distribution) = oneProtoContract.getExpectedReturn(
                oneProtoData.sellToken,
                oneProtoData.buyToken,
                oneProtoData._sellAmt,
                5,
                0
            );

        oneProtoData._buyAmt = oneProtoSwap(
            oneProtoContract,
            oneProtoData
        );

        setUint(setId, oneProtoData._buyAmt);

        emitLogSell(oneProtoData, getId, setId);
    }

    /**
     * @dev Gets the swapping data offchian for swaps and calls swap.
     * @param oneProtoData - Struct with swap data defined in interfaces.sol 
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
     */
    function _sellTwo(
        OneProtoData memory oneProtoData,
        uint getId,
        uint setId
    ) internal {
        uint _sellAmt = getUint(getId, oneProtoData._sellAmt);

        oneProtoData._sellAmt = _sellAmt == uint(-1) ?
            getTokenBal(oneProtoData.sellToken) :
            _sellAmt;

        oneProtoData._buyAmt = oneProtoSwap(
            OneProtoInterface(getOneProtoAddress()),
            oneProtoData
        );

        setUint(setId, oneProtoData._buyAmt);
        emitLogSellTwo(oneProtoData, getId, setId);
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
    ) internal {
        uint _sellAmt = getUint(getId, oneProtoData._sellAmt);

        oneProtoData._sellAmt = _sellAmt == uint(-1) ?
            getTokenBal(oneProtoData.sellToken) :
            _sellAmt;

        oneProtoData._buyAmt = oneProtoSwapMulti(oneProtoData);
        setUint(setId, oneProtoData._buyAmt);

        emitLogSellMulti(oneProtoData, getId, setId);
    }
}

abstract contract OneInchResolverHelpers is OneProtoResolverHelpers {

    /**
     * @dev Gets the swapping data from 1inch's API.
     * @param oneInchData Struct with multiple swap data defined in interfaces.sol 
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
     */
    function _sellThree(
        OneInchData memory oneInchData,
        uint setId
    ) internal {
        TokenInterface _sellAddr = oneInchData.sellToken;

        uint ethAmt;
        if (address(_sellAddr) == getEthAddr()) {
            ethAmt = oneInchData._sellAmt;
        } else {
            TokenInterface(_sellAddr).approve(getOneInchAddress(), oneInchData._sellAmt);
        }

        require(checkOneInchSig(oneInchData.callData), "Not-swap-function");

        oneInchData._buyAmt = oneInchSwap(oneInchData, ethAmt);
        setUint(setId, oneInchData._buyAmt);

        emitLogSellThree(oneInchData, setId);
    }
}

abstract contract OneProto is OneInchResolverHelpers {
    /**
     * @dev Sell ETH/ERC20_Token using 1proto.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function sell(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        uint getId,
        uint setId
    ) external payable {
        OneProtoData memory oneProtoData = OneProtoData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            _sellAmt: sellAmt,
            unitAmt: unitAmt,
            distribution: new uint[](0),
            _buyAmt: 0,
            disableDexes: 0
        });

        _sell(oneProtoData, getId, setId);
    }

    /**
     * @dev Sell ETH/ERC20_Token using 1proto using off-chain calculation.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param distribution distribution of swap across different dex.
     * @param disableDexes disable a dex. (To disable none: 0)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function sellTwo(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        uint[] calldata distribution,
        uint disableDexes,
        uint getId,
        uint setId
    ) external payable {
        OneProtoData memory oneProtoData = OneProtoData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            _sellAmt: sellAmt,
            unitAmt: unitAmt,
            distribution: distribution,
            disableDexes: disableDexes,
            _buyAmt: 0
        });

        _sellTwo(oneProtoData, getId, setId);
    }

    /**
     * @dev Sell ETH/ERC20_Token using 1proto using muliple token.
     * @param tokens array of tokens.
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param distribution distribution of swap across different dex.
     * @param disableDexes disable a dex. (To disable none: 0)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function sellMulti(
        address[] calldata tokens,
        uint sellAmt,
        uint unitAmt,
        uint[] calldata distribution,
        uint[] calldata disableDexes,
        uint getId,
        uint setId
    ) external payable {
        OneProtoMultiData memory oneProtoData = OneProtoMultiData({
            tokens: tokens,
            buyToken: TokenInterface(address(tokens[tokens.length - 1])),
            sellToken: TokenInterface(address(tokens[0])),
            unitAmt: unitAmt,
            distribution: distribution,
            disableDexes: disableDexes,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        _sellMulti(oneProtoData, getId, setId);
    }
}

abstract contract OneInch is OneProto {
    /**
     * @dev Sell ETH/ERC20_Token using 1inch.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param callData Data from 1inch API.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function sellThree(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        bytes calldata callData,
        uint setId
    ) external payable {
        OneInchData memory oneInchData = OneInchData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            unitAmt: unitAmt,
            callData: callData,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        _sellThree(oneInchData, setId);
    }
}

contract ConnectOne is OneInch {
    string public name = "1inch-1proto-v1";
}
