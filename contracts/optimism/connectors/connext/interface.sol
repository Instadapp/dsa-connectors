//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IConnext {
  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32);
}

interface IInstaReceiver {
  function withdraw(
    address _asset,
    uint256 _amount
  ) external returns (bytes memory);

  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  ) external returns (bytes memory);
}