pragma solidity ^0.7.6;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";

// import { SaveWrapper } from "./interface.sol";

// interfaces here
// import { AaveLendingPoolProviderInterface, AaveDataProviderInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	// Helpers go here
	/*
	 * @dev SaveWrapper address
	 */
	// 	SaveWrapper internal constant saveWrapper =
	// 		SaveWrapper(0x299081f52738A4204C3D58264ff44f6F333C6c88);

	// Addresses that will be important for the contract

	address internal constant mUsdToken =
		0xE840B73E5287865EEc17d250bFb1536704B43B21;
	address internal constant imUsdToken =
		0x5290Ad3d83476CA6A2b178Cd9727eE1EF72432af;
	address internal constant imUsdVault =
		0x32aBa856Dc5fFd5A56Bcd182b13380e5C855aa29;
}
