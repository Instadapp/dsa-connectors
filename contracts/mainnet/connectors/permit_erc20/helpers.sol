pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {TokenInterface} from "../../common/interfaces.sol";
import { TokenInterfaceWithPermit, DAITokenInterfaceWithPermit } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    struct SignatureParams {
        uint256 Amount;
        uint256 Deadline;
		uint8 V;
		bytes32 R;
		bytes32 S;
    }

	address constant internal _daiAddress =
		0x6B175474E89094C44Da98b954EedeAC495271d0F;

     /**
     * @dev Returns owner's nonce.
     * @param owner The public address of the user which wants to permit the user to take funds.
     */
    function _getNonceDAI(address owner) internal returns(uint256 nonce){
        DAITokenInterfaceWithPermit token = DAITokenInterfaceWithPermit(_daiAddress);
        return nonce = token.nonces(owner);
    }
}