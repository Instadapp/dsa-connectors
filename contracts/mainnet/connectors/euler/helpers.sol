//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./interface.sol";
import { Basic } from "../../common/basic.sol";

contract Helpers is Basic {

    address internal constant EULER_MAINNET = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
	address internal constant EULER_MAINNET_MARKETS = 0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3;
    IEulerMarkets markets = IEulerMarkets(EULER_MAINNET_MARKETS);

    /**
	 * @dev Get total collateral balance for an asset
	 */
	function getEnteredMarkets()
		internal
		view
		returns (address[] memory enteredMarkets)
	{
		enteredMarkets = markets.getEnteredMarkets(address(this));
	}

}
