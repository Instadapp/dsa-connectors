pragma solidity ^0.7.6;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";

import  "./interface.sol";

abstract contract Helpers is DSMath, Basic {

    IUniverseAdapter constant universeAdapter = IUniverseAdapter(0x876861Ad49f911442720cF97c9b3fCe4070F07d5);

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
        return IVaultV3(universeVault).withdraw(share0, share1);
    }

    function _approve(address universeVault, uint256 amount0, uint256 amount1) internal {
        IVaultV3 universe = IVaultV3(universeVault);
        TokenInterface token;
        if (amount0 > 0) {
            token = universe.token0();
            token.approve(address(universeAdapter), amount0);
        }
        if (amount1 > 0) {
            token = universe.token1();
            token.approve(address(universeAdapter), amount1);
        }
    }

}
