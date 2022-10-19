//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./interface.sol";
import { Basic } from "../../common/basic.sol";

abstract contract Helpers is Basic {
	IMorphoCore public constant MORPHO_COMPOUND =
		IMorphoCore(0x8888882f8f843896699869179fB6E4f7e3B58888);

	IMorphoCore public constant MORPHO_AAVE =
		IMorphoCore(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0);

	IMorphoRewardsDistributor public constant MORPHO_REWARDS =
		IMorphoRewardsDistributor(0x3B14E5C73e0A56D607A8688098326fD4b4292135);
}
