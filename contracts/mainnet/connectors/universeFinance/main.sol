pragma solidity ^0.7.6;
pragma abicoder v2;

import {TokenInterface} from "../../common/interfaces.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

/**
 * @title Universe finance
 * @dev Maximising uniswap v3 returns
 */
abstract contract UniverseFinanceConnect is Helpers, Events {
    /**
     * @notice Deposit in Universe Vault by Adapter
     * @dev Deposit in universe vault
     * @param universeVault Universe Official Vault Address
     * @param amountA Amount of tokenA
     * @param amountB Amount of tokenB
     * @param getIds ID to retrieve amountA and amountB
     * @param setIds ID to store amountA and amountB
     */
    function deposit(
        address universeVault,
        uint256 amountA,
        uint256 amountB,
        uint256[] calldata getIds,
        uint256[] calldata setIds
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        amountA = getUint(getIds[0], amountA);
        amountB = getUint(getIds[1], amountB);
        _approve(universeVault, amountA, amountB);
        (uint256 share0, uint256 share1) = _deposit(
            universeVault,
            amountA,
            amountB
        );
        setUint(setIds[0], share0);
        setUint(setIds[1], share1);
        // EVENT
        _eventName = "LogDeposit(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            universeVault,
            amountA,
            amountB,
            share0,
            share1
        );
    }

    /**
     * @notice Withdraw Token0 & Token1 From Universe Vault
     * @dev Withdraw supplied token0 and token1 from universe vault
     * @param universeVault Universe Official Vault Address
     * @param share0 Amount of uToken0.
     * @param share1 Amount of uToken1.
     * @param getIds ID to retrieve amount of output token
     * @param setIds stores the amount of output tokens
     */
    function withdraw(
        address universeVault,
        uint256 share0,
        uint256 share1,
        uint256[] calldata getIds,
        uint256[] calldata setIds
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        share0 = getUint(getIds[0], share0);
        share1 = getUint(getIds[1], share1);
        (uint256 _amtA, uint256 _amtB) = _withdraw(
            universeVault,
            share0,
            share1
        );
        setUint(setIds[0], _amtA);
        setUint(setIds[1], _amtB);
        // EVENT
        _eventName = "LogWithdraw(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(universeVault, _amtA, _amtB, share0, share1);
    }
}

contract ConnectV2UniverseFinance is UniverseFinanceConnect {
    string public constant name = "UniverseFinance-v1";
}
