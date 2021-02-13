pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { SoloMarginContract } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Solo Margin
     */
    SoloMarginContract internal constant solo = SoloMarginContract(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

    /**
     * @dev Get Dydx Actions args.
    */
    function getActionsArgs(uint256 marketId, uint256 amt, bool sign) internal view returns (SoloMarginContract.ActionArgs[] memory) {
        SoloMarginContract.ActionArgs[] memory actions = new SoloMarginContract.ActionArgs[](1);
        SoloMarginContract.AssetAmount memory amount = SoloMarginContract.AssetAmount(
            sign,
            SoloMarginContract.AssetDenomination.Wei,
            SoloMarginContract.AssetReference.Delta,
            amt
        );
        bytes memory empty;
        SoloMarginContract.ActionType action = sign ? SoloMarginContract.ActionType.Deposit : SoloMarginContract.ActionType.Withdraw;
        actions[0] = SoloMarginContract.ActionArgs(
            action,
            0,
            amount,
            marketId,
            0,
            address(this),
            0,
            empty
        );
        return actions;
    }

    /**
     * @dev Get Dydx Acccount arg
    */
    function getAccountArgs() internal view returns (SoloMarginContract.Info[] memory) {
        SoloMarginContract.Info[] memory accounts = new SoloMarginContract.Info[](1);
        accounts[0] = (SoloMarginContract.Info(address(this), 0));
        return accounts;
    }

    /**
     * @dev Get Dydx Position
    */
    function getDydxPosition(uint256 marketId) internal returns (uint tokenBal, bool tokenSign) {
        SoloMarginContract.Wei memory tokenWeiBal = solo.getAccountWei(getAccountArgs()[0], marketId);
        tokenBal = tokenWeiBal.value;
        tokenSign = tokenWeiBal.sign;
    }

    /**
     * @dev Get Dydx Market ID from token Address
    */
    function getMarketId(address token) internal view returns (uint _marketId) {
        uint markets = solo.getNumMarkets();
        address _token = token == ethAddr ? wethAddr : token;

        for (uint i = 0; i < markets; i++) {
            if (_token == solo.getMarketTokenAddress(i)) {
                _marketId = i;
                break;
            }
        }
    }
}
