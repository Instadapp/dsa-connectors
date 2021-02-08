pragma solidity ^0.7.0;

import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract ChiResolver is Events, Helpers {
    /**
     * @dev Mint CHI token.
     * @param amt token amount to mint.
     */
    function mint(uint amt) public payable {
        uint _amt = amt == uint(-1) ? 140 : amt;
        require(_amt <= 140, "Max minting is 140 chi");
        chi.mint(_amt);
    }

    /**
     * @dev burn CHI token.
     * @param amt token amount to burn.
     */
    function burn(uint amt) public payable {
        uint _amt = amt == uint(-1) ? chi.balanceOf(address(this)) : amt;
        chi.approve(address(chi), _amt);
        chi.free(_amt);
    }
}
contract ConnectCHI is ChiResolver {
    string public name = "CHI-v1";
}
