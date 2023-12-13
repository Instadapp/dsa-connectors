//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Fluid.
 * @dev Lending & Borrowing.
 */

import { Stores } from "../../common/stores.sol";
import { Events } from "./events.sol";
import { IVault } from "./interface.sol";

abstract contract FluidConnector is Events, Stores {
    // todo: add logics when user wants to deposit weth

    function operate(
        address vaultAddress_,
        uint256 nftId_, // if 0 then new position
        int256 newCol_, // if negative then withdraw
        int256 newDebt_, // if negative then payback
        address to_,
		uint256 getId_,
		uint256 setId_
    ) external payable
		returns (string memory _eventName, bytes memory _eventParam) 
    {
        nftId_ = getUint(getId_, nftId_);

        IVault vault_ = IVault(vaultAddress_);

        IVault.ConstantViews memory vaultDetails_ = vault_.constantsView();

        (nftId_, newCol_, newDebt_) = vault_.operate(nftId_, newCol_, newDebt_, to_);

        setUint(setId_, nftId_);

        _eventName = "LogOperate(address,uint256,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(vaultAddress_, nftId_, newCol_, newDebt_, to_, getId_, setId_);
    }
}

contract ConnectV2Fluid is FluidConnector {
	string public constant name = "Fluid-v1.0";
}