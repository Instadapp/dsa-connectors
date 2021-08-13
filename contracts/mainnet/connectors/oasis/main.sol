pragma solidity ^0.7.0;

/**
 * @title OasisDEX.
 * @dev Decentralised Exchange.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { OasisInterface } from "./interface.sol";
import { Events } from "./events.sol";

contract OasisResolver is DSMath, Basic, Events {
    /**
     * @dev Oasis Interface
     */
    OasisInterface internal constant oasis = OasisInterface(0x794e6e91555438aFc3ccF1c5076A74F42133d08D);

    /**
     * @dev Buy ETH/ERC20_Token.
     * @notice Buy tokens using Oasis.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param buyAmt buying token amount.
     * @param unitAmt unit amount of sellAmt/buyAmt with slippage.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function buy(
        address buyAddr,
        address sellAddr,
        uint buyAmt,
        uint unitAmt,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _buyAmt = getUint(getId, buyAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);

        uint _slippageAmt = convert18ToDec(_sellAddr.decimals(), wmul(unitAmt, _buyAmt));

        require(oasis.getBestOffer(_sellAddr, _buyAddr) != 0, "no-offer");
        require(oasis.getMinSell(_sellAddr) <= _slippageAmt, "less-than-min-pay-amt");

        uint _expectedAmt = oasis.getPayAmount(address(_sellAddr), address(_buyAddr), _buyAmt);
        require(_slippageAmt >= _expectedAmt, "Too much slippage");

        bool isEth = address(_sellAddr) == wethAddr;

        convertEthToWeth(isEth, _sellAddr, _expectedAmt);
        approve(_sellAddr, address(oasis), _expectedAmt);

        uint _sellAmt = oasis.buyAllAmount(
            address(_buyAddr),
            _buyAmt,
            address(_sellAddr),
            _slippageAmt
        );

        isEth = address(_buyAddr) == wethAddr;

        convertWethToEth(isEth, _buyAddr, _buyAmt);

        setUint(setId, _sellAmt);

        _eventName = "LogBuy(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
    }

    /**
     * @dev Sell ETH/ERC20_Token.
     * @notice Sell tokens using Oasis.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
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
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _sellAmt = getUint(getId, sellAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);

        if (_sellAmt == uint(-1)) {
            _sellAmt = sellAddr == ethAddr ? address(this).balance : _buyAddr.balanceOf(address(this));
        }

        uint _slippageAmt = convert18ToDec(_buyAddr.decimals(), wmul(unitAmt, _sellAmt));

        require(oasis.getBestOffer(_sellAddr, _buyAddr) != 0, "no-offer");
        require(oasis.getMinSell(_sellAddr) <= _sellAmt, "less-than-min-pay-amt");

        uint _expectedAmt = oasis.getBuyAmount(address(_buyAddr), address(_sellAddr), _sellAmt);
        require(_slippageAmt <= _expectedAmt, "Too much slippage");

        bool isEth = address(_sellAddr) == wethAddr;

        convertEthToWeth(isEth, _sellAddr, _sellAmt);
        approve(_sellAddr, address(oasis), _sellAmt);

        uint _buyAmt = oasis.sellAllAmount(
            address(_sellAddr),
            _sellAmt,
            address(_buyAddr),
           _slippageAmt
        );

        isEth = address(_buyAddr) == wethAddr;

        convertWethToEth(isEth, _buyAddr, _buyAmt);

        setUint(setId, _buyAmt);

        _eventName = "LogSell(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
    }
}

contract ConnectV2Oasis is OasisResolver {
    string public name = "Oasis-v1";
}
