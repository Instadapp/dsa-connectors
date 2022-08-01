//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./interface.sol";
import { Basic } from "../../../common/basic.sol";

contract Helpers is Basic {

    /**
     * @dev Euler Incentives Distributor
     */
    IEulerDistributor internal constant eulerDistribute = IEulerDistributor(0xd524E29E3BAF5BB085403Ca5665301E94387A7e2);

}
