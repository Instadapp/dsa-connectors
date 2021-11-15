pragma solidity ^0.7.6;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";

import  "./interface.sol";

abstract contract Helpers is DSMath, Basic {

    // TODO The vault is currently under audit and the address needs to be updated
    IUniverseAdapter constant universeAdapter = IUniverseAdapter(0x0000000000000000000000000000000000000000);

    function _deposit(
        address universeVault,
        uint256 amount0,
        uint256 amount1
    ) internal returns(uint256, uint256){
        return universeAdapter.depositProxy(universeVault, amount0, amount1);
    }

    function _withdraw(
        address universeVault,
        uint256 share0,
        uint256 share1
    ) internal returns(uint256, uint256){
        require(share0 > 0 || share1 > 0, "ZERO");
        return IUniverseVaultV3(universeVault).withdraw(share0, share1);
    }

}
