pragma solidity ^0.7.6;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";

abstract contract Helpers is DSMath, Basic {
	address internal constant mUsdToken =
		0xe2f2a5C287993345a840Db3B0845fbC70f5935a5;
	address internal constant imUsdToken =
		0x30647a72Dc82d7Fbb1123EA74716aB8A317Eac19;
	address internal constant imUsdVault =
		0x78BefCa7de27d07DC6e71da295Cc2946681A6c7B;
}
