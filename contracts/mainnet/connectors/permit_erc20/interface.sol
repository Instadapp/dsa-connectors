pragma solidity ^0.7.6;

import {TokenInterface} from "../../common/interfaces.sol";

interface ERC20_functions {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(
      address sender,
      address recipient,
      uint amount
  ) external returns (bool);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
  
}

interface ERC20_dai_functions {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(
      address sender,
      address recipient,
      uint amount
  ) external returns (bool);

  function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
  
}