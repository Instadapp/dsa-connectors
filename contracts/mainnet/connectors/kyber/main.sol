pragma solidity ^0.7.0;

/**
 * @title Kyber.
 * @dev Decentralised Swapping.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract KyberResolver is Helpers, Events {
    /**
     * @dev Sell ETH/ERC20_Token.
     * @notice Sell tokens using Kyber.
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

        uint ethAmt;
        if (sellAddr == ethAddr) {
            _sellAmt = _sellAmt == uint(-1) ? address(this).balance : _sellAmt;
            ethAmt = _sellAmt;
        } else {
            TokenInterface sellContract = TokenInterface(sellAddr);
            _sellAmt = _sellAmt == uint(-1) ? sellContract.balanceOf(address(this)) : _sellAmt;
            approve(sellContract, address(kyber), _sellAmt);
        }

        uint _buyAmt = kyber.trade{value: ethAmt}(
            sellAddr,
            _sellAmt,
            buyAddr,
            address(this),
            uint(-1),
            unitAmt,
            referalAddr
        );

        setUint(setId, _buyAmt);

        _eventName = "LogSell(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
    }
}

contract ConnectV2Kyber is KyberResolver {
    string public name = "Kyber-v2";
}