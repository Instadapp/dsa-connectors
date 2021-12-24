pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Lixir Finance.
 * @dev Automated Liquidity Concentrator.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract LixirResolver is Helpers, Events {
    /**
     * @dev Add liqudity to the vault
     * @notice Mint Lixir Vault Tokens
     * @param vault vault address
     * @param amount0Desired amount of tokenA
     * @param amount1Desired amount of tokenB
     * @param amount0Min amount of tokenA
     * @param amount1Min amount of tokenB
     * @param recipient recipient of the Lixir Vault Tokens
     * @param deadline unix timestamp
     * @param getIds ID to retrieve amtA
     * @param setId ID stores the amount of LP token
     */
    function deposit(
        address payable vault,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,  
        address recipient,
        uint256 deadline,      
        uint256[] calldata getIds,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {   
        amount0Desired = getUint(getIds[0], amount0Desired);
        amount1Desired = getUint(getIds[1], amount1Desired);
    
        (
            uint256 shares,
            uint256 amount0In,
            uint256 amount1In
        ) = _deposit(
            vault,
            amount0Desired,
            amount1Desired,
            amount0Min,
            amount1Min,
            recipient,
            deadline
        );

        setUint(setId, shares);

        _eventName = "LogDeposit(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            vault,
            shares,
            amount0In,
            amount1In
        );
    }

    /**
     * @dev Decrease Liquidity
     * @notice Withdraw Liquidity from Lixir Vault
     * @param vault Lixir vault address
     * @param shares the amount of Lixir Vault Tokens to remove
     * @param amount0Min Min amount of token0.
     * @param amount1Min Min amount of token1.
     * @param deadline unix timestamp
     * @param getId ID to retrieve LP token amounts
     * @param setIds stores the amount of output tokens
     */
    function withdraw(
        address vault,
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min,
        address recipient,
        uint256 deadline,
        uint256 getId,
        uint256[] calldata setIds
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        address vault = address(getUint(getId, uint256(vault))); // unsure of this...

        (uint256 amount0Out, uint256 amount1Out) = _withdraw(
            vault,
            shares,
            amount0Min,
            amount1Min,
            recipient,
            deadline
        );

        setUint(setIds[0], amount0Out);
        setUint(setIds[1], amount1Out);

        _eventName = "LogWithdraw(address,uint256,uint256)";
        _eventParam = abi.encode(vault, amount0Out, amount1Out);
    }
}

contract ConnectV2Lixir is LixirResolver {
    string public constant name = "Lixir-v1";
}
