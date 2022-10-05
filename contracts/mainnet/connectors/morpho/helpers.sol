//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./interface.sol";
import "../../common/stores.sol";
import "../../common/basic.sol";
import "../../common/interfaces.sol";

abstract contract Helpers is Stores, Basic {
	IMorphoCore public constant morphoCompound =
		IMorphoCore(0x8888882f8f843896699869179fB6E4f7e3B58888);
	IMorphoCore public constant morphoAave =
		IMorphoCore(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0);

	enum Underlying {
		AAVEV2,
		COMPOUNDV2
	}
}
