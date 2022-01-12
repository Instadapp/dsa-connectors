pragma solidity ^0.7.6;
pragma abicoder v2;

import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    function _deposit(
        address payable vaultAddress,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address recipient,
        uint256 deadline
    ) internal returns (
        uint256 shares,
        uint256 amount0In,
        uint256 amount1In
    ) {
        uint256 shares;
        uint256 amount0In;
        uint256 amount1In;

        if (msg.value > 0) {
            ILixirVaultETH vault = ILixirVaultETH(vaultAddress);

            (
                shares,
                amount0In,
                amount1In
            ) = vault.depositETH(
                uint8(vault.WETH_TOKEN()) == 1 ? amount0Desired : amount1Desired,
                uint8(vault.WETH_TOKEN()) == 1 ? amount0Min : amount1Min,
                uint8(vault.WETH_TOKEN()) == 1 ? amount1Min : amount0Min,
                recipient,
                deadline
            );
        } else {
            ILixirVault vault = ILixirVault(vaultAddress);
            (
                shares,
                amount0In,
                amount1In
            ) = vault.deposit(
                amount0Desired,
                amount1Desired,
                amount0Min,
                amount1Min,
                recipient,
                deadline
            );
        }
  }

    function _withdraw(
        address vaultAddress,
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min,
        address recipient,
        uint256 deadline
    ) internal returns (uint256 amount0Out, uint256 amount1Out) {
        ILixirVault vault = ILixirVault(vaultAddress);
        (
            amount0Out,
            amount1Out
        ) = vault.withdraw(
            shares,
            amount0Min,
            amount1Min,
            recipient,
            deadline
        );
    }
}
