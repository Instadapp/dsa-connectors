// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import {TokenInterface} from "../../../common/interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	using SafeERC20 for IERC20;

	INFT internal constant nftManager =
		INFT(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

	IProtocolModule internal constant protocolModule =
		IProtocolModule(0xf0404BC3673B271B40b554F92879BC15A7100bA0);

	struct BorrowingReward {
        address token;
        address[] rewardTokens;
        uint256[] rewardAmounts;
    }

	 struct Liquidate0Parameters {
        uint96 NFTID;
        uint256 liquidityDecreasePercentage;
        uint256 paybackAmount0Max;
        uint256 paybackAmount1Max;
    }

    struct Liquidate0Variables {
        uint256 tokenAmount0;
        uint256 tokenAmount1;
        uint256 paybackAmount0;
        uint256 paybackAmount1;
        uint256 incentiveAmount0;
        uint256 incentiveAmount1;
        uint256 paybackAmount0WithIncentive;
        uint256 paybackAmount1WithIncentive;
    }

	 struct Liquidate1Parameters {
        uint96 NFTID;
        uint256[] amounts;
    }

    struct Liquidate1Variables {
        uint256 paybackInUsd;
        uint256 toPaybackInUsd;
        uint256 fee0InUsd;
        uint256 fee1InUsd;
        uint256 feeInUsd;
        uint256 collateralWithoutFeeInUsd;
        uint256 exactAmount0;
        uint256 exactAmount1;
        address[] markets;
        uint256[] paybackAmts;
    }

	struct BorrowingReward {
        address token;
        address[] rewardTokens;
        uint256[] rewardAmounts;
    }

}
