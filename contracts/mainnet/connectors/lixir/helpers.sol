pragma solidity ^0.7.6;
pragma abicoder v2;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    ILixirFactory constant factory =
        ILixirFactory(0xFbC744df515F8962C18e79795F469d57EC460691);

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
            ) = (0, 0, 0);
            // ) = vault.depositETH(
            //     amountDesired,
            //     amountEthMin,
            //     amountMin,
            //     recipient,
            //     deadline
            // );
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
    address withdrawer,
    uint256 shares,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient,
    uint256 deadline
  ) internal returns (uint256 amount0Out, uint256 amount1Out) {
    return (0, 0);
  }

  function _withdrawETH(
    address withdrawer,
    uint256 shares,
    uint256 amountEthMin,
    uint256 amountMin,
    address payable recipient,
    uint256 deadline
  ) internal returns (uint256 amountEthOut, uint256 amountOut) {
    return (0, 0);
  }
}
