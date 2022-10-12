//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./interface.sol";
import "../../common/stores.sol";
import "../../common/basic.sol";
import "../../common/interfaces.sol";

abstract contract Helpers is Stores, Basic {
	IMorphoCore public constant morphoAave =
		IMorphoCore(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0);

	IMorphoAaveLens public constant morphoAaveLens =
		IMorphoAaveLens(0x507fA343d0A90786d86C7cd885f5C49263A91FF4);
}
