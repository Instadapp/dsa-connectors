pragma solidity ^0.7.0;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { StakedAaveInterface, AaveInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {

    enum DelegationType {VOTING_POWER, PROPOSITION_POWER, BOTH}

    /**
     * @dev Staked Aave Token
    */
    StakedAaveInterface internal constant stkAave = StakedAaveInterface(0x4da27a545c0c5B758a6BA100e3a049001de870f5);

    /**
     * @dev Aave Token
    */
    AaveInterface internal constant aave = AaveInterface(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);

    function _delegateAave(address _delegatee, DelegationType _type) internal {
        if (_type == DelegationType.BOTH) {
            require(
                aave.getDelegateeByType(address(this), 0) != _delegatee,
                "already-delegated"
            );
            require(
                aave.getDelegateeByType(address(this), 1) != _delegatee,
                "already-delegated"
            );

            aave.delegate(_delegatee);
        } else if (_type == DelegationType.VOTING_POWER) {
            require(
                aave.getDelegateeByType(address(this), 0) != _delegatee,
                "already-delegated"
            );

            aave.delegateByType(_delegatee, 0);
        } else {
            require(
                aave.getDelegateeByType(address(this), 1) != _delegatee,
                "already-delegated"
            );

            aave.delegateByType(_delegatee, 1);
        }
    }

    function _delegateStakedAave(address _delegatee, DelegationType _type) internal {
        if (_type == DelegationType.BOTH) {
            require(
                stkAave.getDelegateeByType(address(this), 0) != _delegatee,
                "already-delegated"
            );
            require(
                stkAave.getDelegateeByType(address(this), 1) != _delegatee,
                "already-delegated"
            );

            stkAave.delegate(_delegatee);
        } else if (_type == DelegationType.VOTING_POWER) {
            require(
                stkAave.getDelegateeByType(address(this), 0) != _delegatee,
                "already-delegated"
            );

            stkAave.delegateByType(_delegatee, 0);
        } else {
            require(
                stkAave.getDelegateeByType(address(this), 1) != _delegatee,
                "already-delegated"
            );

            stkAave.delegateByType(_delegatee, 1);
        }
    }
}