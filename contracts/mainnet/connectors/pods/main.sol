pragma solidity ^0.7.0;

/**
 * @title Pods.
 * @dev Manage Pods to DSA.
 */
import {TokenInterface} from "../../common/interfaces.sol";
import {Events} from "./events.sol";
import {IOptionAMMPool} from "./interface.sol";

abstract contract PodsResolver is Events, Helpers {
    /**
     * @notice addLiquidity in any proportion of tokenA or tokenB
     *
     * @dev This function can only be called before option expiration
     *
     * @param pool pool address
     * @param amountOfA amount of TokenA to add
     * @param amountOfB amount of TokenB to add
     * @param owner address of the account that will have ownership of the liquidity
     */
    function addLiquidity(
        address pool,
        uint256 amountOfA,
        uint256 amountOfB,
        address owner
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        IOptionAMMPool ammPool = IOptionAMMPool(pool);

        TokenInterface tokenA = TokenInterface(ammPool.tokenA());
        approve(tokenA, pool, tokenA.balanceOf(address(this)));

        TokenInterface tokenB = TokenInterface(ammPool.tokenB());
        approve(tokenB, pool, tokenB.balanceOf(address(this)));

        ammPool.addLiquidity(amountOfA, amountOfB, owner);

        _eventName = "LogAddLiquidity(address,uint256,uint256,address)";
        _eventParam = abi.encode(pool, amountOfA, amountOfB, owner);
    }

    /**
     * @notice removeLiquidity in any proportion of tokenA or tokenB
     * @dev removeLiquidity in any proportion of tokenA or tokenB
     *
     * @param pool pool address
     * @param amountOfA amount of TokenA to add
     * @param amountOfB amount of TokenB to add
     */
    function removeLiquidity(
        address pool,
        uint256 amountOfA,
        uint256 amountOfB
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        IOptionAMMPool ammPool = IOptionAMMPool(pool);
        ammPool.removeLiquidity(amountOfA, amountOfB);

        _eventName = "LogRemoveLiquidity(address,uint256,uint256)";
        _eventParam = abi.encode(pool, amountOfA, amountOfB);
    }

    /**
     * @notice withdrawRewards claims reward from Aave and send to admin
     * @dev should only be called by the admin power
     *
     * @param pool pool address
     */
    function withdrawRewards(address pool)
        external
        returns (string memory _eventName, bytes memory _eventParam)
    {
        IOptionAMMPool ammPool = IOptionAMMPool(pool);
        ammPool.withdrawRewards();

        _eventName = "LogWithdrawRewards(address)";
        _eventParam = abi.encode(pool);
    }
}

contract ConnectV2Pods is PodsResolver {
    string public constant name = "Pods-v1";
}
