//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {

    address internal constant CRV_USD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
    /**
     * @dev ControllerFactory Interface
     */
    IControllerFactory internal constant ctrFactory = IControllerFactory(0xC9332fdCB1C491Dcc683bAe86Fe3cb70360738BC);

    /**
     * @dev Get controller address by given collateral asset
     */
    function getController(address collateral, uint256 i) internal view returns(IController controller) {
        controller = IController(ctrFactory.get_controller(collateral, i));
    }
}