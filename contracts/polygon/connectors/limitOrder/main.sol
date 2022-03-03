pragma solidity ^0.8.1;
// SPDX-License-Identifier: MIT

import {Helpers} from "./helpers.sol";
import {IUniLimitOrder} from "./interface.sol";
import {TokenInterface} from "../../common/interfaces.sol";

/**
 * @title LimitOrderConnector.
 * @dev Connector for Limit Order Swap on Uni V3.
 */
contract LimitOrderConnector is Helpers {

    function create(
        address token0_,
        address token1_,
        uint24 fee_,
        int24 tickLower_,
        int24 tickUpper_,
        uint256 amount_,
        bool token0to1_,
        uint256 getId_,
        uint256 setId_
    )
        external
        payable
        returns (string memory eventName_, bytes memory eventParam_)
    {

        MintParams memory params_ = MintParams(
                token0_,
                token1_,
                fee_,
                tickLower_,
                tickUpper_,
                amount_,
                token0to1_
            );

        params_.amount = getUint(getId_, amount_);

        (
            uint256 tokenId_,
            uint256 liquidity_,
            uint256 minAmount_
        ) = _createPosition(params_);

        setUint(setId_, liquidity_);

        eventName_ = "LogCreate(uint256,uint256,uint256,int24,int24)";
        _eventParam = abi.encode(
            tokenId_,
            liquidity_,
            minAmount_,
            params_.tickLower,
            params_.tickUpper
        );
    }


    function closeMid(
        uint256 tokenId_,
        uint256 amountAMin_,
        uint256 amountBMin_,
        uint256[] calldata setIds_
    )
        external
        payable
        returns (string memory eventName_, bytes memory eventParam_)
    {

        (uint128 liquidity_, uint256 amount0, uint256 amount1) = limitCon_.closeMidPosition(tokenId_, amountAMin_, amountBMin_);

        setUint(setIds_[0], amount0);
        setUint(setIds_[1], amount1);

        eventName_ = "LogWithdrawMid(uint256,uint256,uint256,uint256)";
        eventParam_ = abi.encode(tokenId_, liquidity_, amount0, amount1);
    }


    function closeFull(
        uint256 tokenId_,
        uint256 setId_
    )
        external
        payable
        returns (string memory eventName_, bytes memory eventParam_)
    {

        (uint256 closeAmount_) = limitCon_.closeFullPosition(tokenId_);

        setUint(setId_, closeAmount_);

        eventName_ = "LogWithdrawFull(uint256,uint256)";
        eventParam_ = abi.encode(tokenId_, closeAmount_);
    }  

}

contract ConnectV2LimitOrder is LimitOrderConnector {
    string public constant name = "Limit-Order-Connector";
}