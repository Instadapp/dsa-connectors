pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { TokenInterface, MemoryInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { TokenInterfaceWithPermit, DAITokenInterfaceWithPermit } from "./interface.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

/**
 * @title ERC20 Permit.
 * @dev Deposit ERC20 using Permit.
 */
contract ERC20PermitResolver is Stores, Helpers {
	address internal constant daiAddress =
		0x6B175474E89094C44Da98b954EedeAC495271d0F; // dai has a different implementation for permit

	/**
	 * @notice Deposit ERC20 using Permit
	 * @dev Deposing ERC20 using Permit functionality. https://eips.ethereum.org/EIPS/eip-2612
	 * @param token The address of the token to call.(For AAVE Token : 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9)
	 * @param owner The public address of the user which wants to permit the user to take funds.
	 * @param amount The amount of the token permitted by the owner (No need to specify in DAI, you get access to all the funds in DAI).
	 * @param deadline The deadline for permit.
	 * @param v The signature variable provided by the owner.
	 * @param r The signature variable provided by the owner.
	 * @param s The signature variable provided by the owner.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposit.
	 */
	function depositWithPermit(
		address token,
		address owner,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s,
		uint256 getId,
		uint256 setId
	) external payable returns (string memory _eventName, bytes memory _eventParam) {
		Helpers.SignatureParams memory signatureParams = Helpers
			.SignatureParams({
				Amount: amount,
				Deadline: deadline,
				V: v,
				R: r,
				S: s
			});
			
		uint256 _amt = getUint(getId, amount);

		if (token == daiAddress) {
			DAITokenInterfaceWithPermit token = DAITokenInterfaceWithPermit(token);
			uint256 nonce = _getNonceDAI(owner);
			token.permit(
				owner,
				address(this),
				nonce,
				signatureParams.Deadline,
				true,
				signatureParams.V,
				signatureParams.R,
				signatureParams.S
			);
			token.transferFrom(owner, address(this), _amt);
		} else {
			TokenInterfaceWithPermit token = TokenInterfaceWithPermit(token);
			token.permit(
				owner,
				address(this),
				signatureParams.Amount,
				signatureParams.Deadline,
				signatureParams.V,
				signatureParams.R,
				signatureParams.S
			);
			token.transferFrom(owner, address(this), _amt);
		}

		setUint(setId, _amt);

		_eventName = "logDepositWithPermit(address,address,uint256,uint256,uint8,bytes32,bytes32,uint256,uint256)";
		_eventParam = abi.encode(
			token,
			owner,
			signatureParams.Amount,
			signatureParams.Deadline,
			signatureParams.V,
			signatureParams.R,
			signatureParams.S,
			getId,
			setId
		);
	}
}

contract ConnectV2ERC20Permit is ERC20PermitResolver {
	string public name = "ERC20PermitResolver";
}
