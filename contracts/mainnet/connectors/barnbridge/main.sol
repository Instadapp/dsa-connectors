
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title BarnBridge.
 * @dev BarnBridge Smart Yield.
 */

 import { TokenInterface } from "../../common/interfaces.sol";

 import {
    AaveV2LendingPoolProviderInterface, 
    AaveV2DataProviderInterface,
    AaveV2Interface,
    ComptrollerInterface,
    CTokenInterface,
    CompoundMappingInterface,
    CreamMappingInterface
} from "./interfaces.sol";

import { AaveV2Helpers } from "./helpers/aaveV2.sol";
import { CompoundHelpers } from "./helpers/compound.sol";
import { CreamHelpers } from "./helpers/cream.sol";
import { BarnBridgeHelpers } from "./helpers/barnbridge.sol";

import { ISmartYield } from './ISmartYield.sol';
import { Events } from "./events.sol";


abstract contract BarnBridgeResolver is CompoundHelpers, CreamHelpers, AaveV2Helpers, BarnBridgeHelpers, Events {
    SmartYield internal constant barnBridge = ISmartYield(0x4b8d90d68f26def303dcb6cfc9b63a1aaec15840);
    
    struct BarnBridgeData {
        Protocol source;
        Protocol target;
        uint collateralFee;
        uint debtFee;
        address[] tokens;
        string[] ctokenIds;
        uint[] borrowAmts;
        uint[] withdrawAmts;
        uint[] depositAmts;
        uint[] borrowRateModes;
        uint[] paybackRateModes;
    }

    struct BarnBridgeInternalData {
        AaveV2Interface aaveV2;
        AaveV1Interface aaveV1;
        AaveV1CoreInterface aaveCore;
        AaveV2DataProviderInterface aaveData;
        uint[] depositAmts;
        uint[] paybackAmts;
        TokenInterface[] tokens;
        CTokenInterface[] _ctokens;
    }

    
    
    // ===== SmartYield ENTRY APIs ======

    /**
     * @dev BarnBridge
     * @notice buyTokens - buy at least _minTokens with _underlyingAmount, before _deadline passes
     * @param underlyingAmount_ 
     * @param minTokens_ 
     * @param deadline_ 
    */
    function buyTokens(
      uint256 underlyingAmount_,
      uint256 minTokens_,
      uint256 deadline_
    )
      external override
    {
        _beforeProviderOp(block.timestamp);

        require(
          false == IController(controller).PAUSED_BUY_JUNIOR_TOKEN(),
          "SY: buyTokens paused"
        );

        require(
          block.timestamp <= deadline_,
          "SY: buyTokens deadline"
        );

        uint256 fee = MathUtils.fractionOf(underlyingAmount_, IController(controller).FEE_BUY_JUNIOR_TOKEN());
        // (underlyingAmount_ - fee) * EXP_SCALE / price()
        uint256 getsTokens = (underlyingAmount_.sub(fee)).mul(EXP_SCALE).div(price());

        require(
          getsTokens >= minTokens_,
          "SY: buyTokens minTokens"
        );

        // ---

        address buyer = msg.sender;

        IProvider(pool)._takeUnderlying(buyer, underlyingAmount_);
        IProvider(pool)._depositProvider(underlyingAmount_, fee);
        _mint(buyer, getsTokens);

        emit BuyTokens(buyer, underlyingAmount_, getsTokens, fee);
    }

    function sellTokens(
      uint256 tokenAmount_,
      uint256 minUnderlying_,
      uint256 deadline_
    )
      external override
    {
        _beforeProviderOp(block.timestamp);

        require(
          block.timestamp <= deadline_,
          "SY: sellTokens deadline"
        );

        // share of these tokens in the debt
        // tokenAmount_ * EXP_SCALE / totalSupply()
        uint256 debtShare = tokenAmount_.mul(EXP_SCALE).div(totalSupply());
        // (abondDebt() * debtShare) / EXP_SCALE
        uint256 forfeits = abondDebt().mul(debtShare).div(EXP_SCALE);
        // debt share is forfeit, and only diff is returned to user
        // (tokenAmount_ * price()) / EXP_SCALE - forfeits
        uint256 toPay = tokenAmount_.mul(price()).div(EXP_SCALE).sub(forfeits);

        require(
          toPay >= minUnderlying_,
          "SY: sellTokens minUnderlying"
        );

        // ---

        address seller = msg.sender;

        _burn(seller, tokenAmount_);
        IProvider(pool)._withdrawProvider(toPay, 0);
        IProvider(pool)._sendUnderlying(seller, toPay);

        emit SellTokens(seller, tokenAmount_, toPay, forfeits);
    }
}

contract ConnectV2BarnBridge is BarnBridgeResolver {
    string public name = "BarnBridge-v1";
}