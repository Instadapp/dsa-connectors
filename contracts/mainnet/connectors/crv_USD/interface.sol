//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";

interface IControllerFactory {
    function get_controller(address collateral, uint256 index) external view returns (address);
}

interface IController {
    function create_loan(uint256 collateral, uint256 debt, uint256 N) payable external;
    function add_collateral(uint256 collateral, address _for) payable external;
    function remove_collateral(uint256 collateral, bool use_eth) external;
    function borrow_more(uint256 collateral, uint256 debt) payable external;
    function repay(uint256 _d_debt, address _for, int256 max_active_band, bool use_eth) payable external;
    function liquidate(address user, uint256 min_x, bool use_eth) external;
    function max_borrowable(uint256 collateral, uint256 N) external view returns(uint256);
    function min_collateral(uint256 debt, uint256 N) external view returns(uint256);
    function user_state(address user) external view returns(uint256[] memory);
}
