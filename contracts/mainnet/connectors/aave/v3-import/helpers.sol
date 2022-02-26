pragma solidity ^0.7.0;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { AaveInterface, IFlashLoan, AaveLendingPoolProviderInterface, AaveDataProviderInterface } from "./interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract Helpers is DSMath, Basic {
	/**
	 * @dev Aave referal code
	 */
	uint16 internal constant referalCode = 3228;

	/**
	 * @dev Aave Lending Pool Provider
	 */
	AaveLendingPoolProviderInterface internal constant aaveProvider =
		AaveLendingPoolProviderInterface(
			0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
		);

	/**
	 * @dev Aave Protocol Data Provider
	 */
	AaveDataProviderInterface internal constant aaveData =
		AaveDataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

	address flashloanAddr = 0x619Ad2D02dBeE6ebA3CDbDA3F98430410e892882;

	function getIsColl(address token, address user)
		internal
		view
		returns (bool isCol)
	{
		(, , , , , , , , isCol) = aaveData.getUserReserveData(token, user);
	}
}
