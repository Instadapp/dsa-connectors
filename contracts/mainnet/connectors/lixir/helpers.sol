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
    address vault,
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
    return (0, 0, 0);
  }

  function _depositETH(
    address vault,
    uint256 amountDesired,
    uint256 amountEthMin,
    uint256 amountMin,
    address recipient,
    uint256 deadline
  ) internal returns (
    uint256 shares,
    uint256 amountEthIn,
    uint256 amountIn
  ) {
    return (0, 0, 0);
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
