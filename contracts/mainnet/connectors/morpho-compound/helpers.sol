//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./interface.sol";
import "../../common/stores.sol";
import "../../common/basic.sol";
import "../../common/interfaces.sol";

abstract contract Helpers is Stores, Basic {
	IMorphoCore public constant MORPHO_COMPOUND =
		IMorphoCore(0x8888882f8f843896699869179fB6E4f7e3B58888);

	IMorphoCompoundLens public constant morphoCompoundLens =
		IMorphoCompoundLens(0x930f1b46e1D081Ec1524efD95752bE3eCe51EF67);
}
