pragma solidity ^0.7.6;
pragma abicoder v2;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
  ILixirFactory constant factory =
    ILixirFactory(0xfbc744df515f8962c18e79795f469d57ec460691);

  function _deposit(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient,
    uint256 deadline
  ) returns (
    uint256 shares,
    uint256 amount0In,
    uint256 amount1In
  ) {

  }


  function _depositETH(
    uint256 amountDesired,
    uint256 amountEthMin,
    uint256 amountMin,
    address recipient,
    uint256 deadline
  ) returns (
    uint256 shares,
    uint256 amountEthIn,
    uint256 amountIn
  ) {

  }


  function _withdraw(

  ) returns () {

  }

  function _withdrawETH(

  ) returns () {

  }
}
