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

 /* put the dev, vghra details and the parms and cases ofr dai and aave*/

contract permit_erc20 {
    address dai_address = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

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
        if(_asset==dai_address){
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
