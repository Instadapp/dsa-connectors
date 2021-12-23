pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Lixir Finance.
 * @dev Automated Liquidity Concentrator.
 */

import {TokenInterface} from "../../common/interfaces.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

abstract contract LixirResolver is Helpers, Events {
    /**
     * @dev Add liqudity to the vault
     * @notice Mint Lixir Vault Tokens
     * @param token0 token0 address
     * @param token1 token1 address
     * @param amount0 amount of tokenA
     * @param amount1 amount of tokenB
     * @param getIds ID to retrieve amtA
     * @param setId ID stores the amount of LP token
     */
    function desosit(
        address token0,
        address token1,
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
        // grab the correct vault from the factory

        // check if one of these is ETH, you have to use depositETH, not deposit
        
        // MintParams memory params;
        // {
        //     params = MintParams(
        //         tokenA,
        //         tokenB,
        //         fee,
        //         tickLower,
        //         tickUpper,
        //         amtA,
        //         amtB,
        //         slippage
        //     );
        // }
        // params.amtA = getUint(getIds[0], params.amtA);
        // params.amtB = getUint(getIds[1], params.amtB);

        // (
        //     uint256 _tokenId,
        //     uint256 liquidity,
        //     uint256 amountA,
        //     uint256 amountB
        // ) = _mint(params);

        // setUint(setId, liquidity);

        _eventName = "LogDeposit(uint256,uint256,uint256,uint256,int24,int24)";
        _eventParam = abi.encode(
            vault
        );
    }

    /**
     * @dev Decrease Liquidity
     * @notice Withdraw Liquidity from Lixir Vault
     * @param vault Lixir vault address
     * @param withdrawer the DSA account
     * @param shares the amount of Lixir Vault Tokens to remove
     * @param amount0Min Min amount of token0.
     * @param amount1Min Min amount of token1.
     * @param getId ID to retrieve LP token amounts
     * @param setIds stores the amount of output tokens
     */
    function withdraw(
        address vault,
        address withdrawer,
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
        // if (tokenId == 0) tokenId = _getLastNftId(address(this));
        // uint128 _liquidity = uint128(getUint(getId, liquidity));

        // (uint256 _amtA, uint256 _amtB) = _decreaseLiquidity(
        //     tokenId,
        //     _liquidity,
        //     amountAMin,
        //     amountBMin
        // );

        // setUint(setIds[0], _amtA);
        // setUint(setIds[1], _amtB);

        _eventName = "LogWithdraw(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(vault);
    }
}

contract ConnectV2Lixir is LixirResolver {
    string public constant name = "Lixir-v1";
}
