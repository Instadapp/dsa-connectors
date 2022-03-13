pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { TokenInterface, MemoryInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { TokenInterfaceWithPermit, DAITokenInterfaceWithPermit } from "./interface.sol";
//import {Helpers} from "./helpers.sol";
import { Events } from "./events.sol";

/**
 * @title ERC20 Permit.
 * @dev Deposit ERC20 using Permit.
 */

contract ERC20PermitResolver is Stores {
	address constant internal daiAddress =
		0x6B175474E89094C44Da98b954EedeAC495271d0F; // dai has a different implementation for permit

	/**
	 * @notice Deposit ERC20 using Permit
	 * @dev Deposing ERC20 using Permit functionality. https://eips.ethereum.org/EIPS/eip-2612
	 * @param token The address of the token to call.(For AAVE Token : 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9)
	 * @param owner The public of the user which wants to permit the user to take funds.
	 * @param nonce The nonce of the user(Neede only if asset is DAI)  //can add helper here
	 * @param amount The amount of the token permitted by the owner (No need to specify in DAI, you get access to all the funds in DAI).
	 * @param deadline The deadline for permit.
	 * @param v The signature variable provided by the owner.
	 * @param r The signature variable provided by the owner.
	 * @param s The signature variable provided by the owner.
	 */
	function depositWithPermit(
		address token,
		address owner,
		uint256 nonce,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s,
		uint256 getId,
		uint256 setId
	) external returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _amt = getUint(getId, amount);

		if (token == daiAddress) {
			DAITokenInterfaceWithPermit token = DAITokenInterfaceWithPermit(token);
			token.permit(owner, address(this), nonce, deadline, true, v, r, s);
			token.transferFrom(owner, address(this), _amt);
		} else {
			TokenInterfaceWithPermit token = TokenInterfaceWithPermit(token);
			token.permit(owner, address(this), amount, deadline, v, r, s);
			token.transferFrom(owner, address(this), _amt);
		}

		setUint(setId, _amt);

		_eventName = "logDepositWithPermit(address,address,uint256,uint256,uint256,uint8,bytes32,bytes32,uint256,uint256)";
		_eventParam = abi.encode(
			token,
			owner,
			nonce,
			amount,
			deadline,
			v,
			r,
			s,
			getId,
			setId
		);
	}
}

contract ConnectV2ERC20Permit is ERC20PermitResolver {
	string public name = "ERC20PermitResolver";
}
