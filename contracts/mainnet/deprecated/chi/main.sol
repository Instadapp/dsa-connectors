//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract ChiResolver is Events, Helpers {
    /**
     * @dev Mint token.
     * @notice Mint CHI token.
     * @param amt token amount to mint.
     */
    function mint(uint amt) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = amt == uint(-1) ? 140 : amt;
        require(_amt <= 140, "Max minting is 140 chi");
        chi.mint(_amt);

        _eventName = "LogMint(uint256)";
        _eventParam = abi.encode(_amt);
    }

    /**
     * @dev Burn token.
     * @notice burns CHI token.
     * @param amt token amount to burn.
     */
    function burn(uint amt) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = amt == uint(-1) ? chi.balanceOf(address(this)) : amt;
        chi.approve(address(chi), _amt);
        chi.free(_amt);

        _eventName = "LogBurn(uint256)";
        _eventParam = abi.encode(_amt);
    }
}
contract ConnectV2CHI is ChiResolver {
    string public name = "CHI-v1";
}
