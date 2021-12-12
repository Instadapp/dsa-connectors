pragma solidity ^0.7.0;

import {TokenInterface} from "../../common/interfaces.sol";

interface zeroExInterface {
    function getTransformWallet() external view returns (IFlashWallet wallet);
}

interface IFlashWallet {
    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @param value Ether to attach to the call.
    /// @return resultData The data returned by the call.
    function executeCall(
        address payable target,
        bytes calldata callData,
        uint256 value
    ) external payable returns (bytes memory resultData);

    /// @dev Execute an arbitrary delegatecall, in the context of this puppet.
    ///      Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeDelegateCall(
        address payable target,
        bytes calldata callData
    ) external payable returns (bytes memory resultData);

    /// @dev Allows the puppet to receive ETH.
    receive() external payable;

    /// @dev Fetch the immutable owner/deployer of this contract.
    /// @return owner_ The immutable owner/deployer/
    function owner() external view returns (address owner_);
}

struct ZeroExData {
    TokenInterface sellToken;
    TokenInterface buyToken;
    uint256 _sellAmt;
    uint256 _buyAmt;
    uint256 unitAmt;
    bytes callData;
}
