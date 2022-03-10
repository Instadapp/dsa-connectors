pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {TokenInterface, MemoryInterface} from "../../common/interfaces.sol";
import {Stores} from "../../common/stores.sol";
import {ERC20_functions, ERC20_dai_functions} from "./interface.sol";
//import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

/**
 * @title permit_erc20.
 * @dev Adding permit functionality to ERC_20.
 */


contract permit_erc20 {
    address private immutable daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // dai has a different implementation for permit

    /**
     * @notice ERC20_Permit functionality
     * @dev Adding permit functionality to ERC_20.
     * @param _asset The address of the token to call.(For AAVE Token : 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9)
     * @param _owner The public of the user which wants to permit the user to take funds.(Ex: - 0x3Fc046bdE274Fe8Ed2a7Fd008cD9DEB2540dfE36 )
     * @param nonce The nonce of the user(Neede only if asset is DAI)  //can add helper here
     * @param _amount The amount of the token permitted by the owner (No need to specify in DAI, you get access to all the funds in DAI).
     * @param _deadline The deadline decided by the owner.
     * @param v The signature variable provided by the owner.
     * @param r The signature variable provided by the owner.
     * @param s The signature variable provided by the owner.
     */
    function depositWithPermit(
        address _asset,
        address _owner, 
        uint256 nonce, 
        uint256 _amount, 
        uint256 _deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) 
        external
        returns (string memory _eventName, bytes memory _eventParam) 
    {
        if(_asset==daiAddress){
            ERC20_dai_functions token = ERC20_dai_functions(_asset);
            token.permit(_owner, address(this), nonce, _deadline, true, v, r, s);
            token.transferFrom(_owner, address(this), _amount);
        }
        else{
            ERC20_functions token = ERC20_functions(_asset);
            token.permit(_owner, address(this), _amount, _deadline, v, r, s);
            token.transferFrom(_owner, address(this), _amount);
        }

        _eventName = "depositWithPermit(address,address,uint256,uint256,uint256,uint8,bytes32,bytes32)";
        _eventParam = abi.encode(
            _asset,
            _owner,
            nonce,
            _amount,
            _deadline,
            v,
            r,
            s
        );

    }

}

contract ConnectV2Permit_erc20 is permit_erc20{
    string public name = "permit_erc20";
}
