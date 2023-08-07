//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title MakerDAO.
 * @dev Collateralized Borrowing.
 */

import { TokenInterface, AccountInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import "./interface.sol";

abstract contract MakerResolver is Helpers, Events {
    /**
     * @dev Create loan
     * @param collateral collateral token address
     * @param amt Amount of collateral to use
     * @param debt Stablecoin debt to take
     * @param N Number of bands to deposit into (to do autoliquidation-deliquidation), can be from MIN_TICKS(4) to MAX_TICKS(50)
    */
    function createLoan(
        address collateral, 
        uint256 amt,
        uint256 debt, 
        uint256 N
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        address _collateral = collateral == ethAddr ? wethAddr : collateral;
        IController controller = getController(_collateral);
        uint256 _amt = amt;

        uint256 ethAmt;
        if (collateral == ethAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            ethAmt = _amt;
        } else {
            TokenInterface collateralContract = TokenInterface(_collateral);
            _amt = _amt == uint(-1) ? collateralContract.balanceOf(address(this)) : _amt;
            approve(collateralContract, address(controller), _amt);
        }

        uint256 _debt = debt == uint(-1) ? controller.max_borrowable(_amt, N) : debt;

        controller.create_loan{value: ethAmt}(_amt, _debt, N);
        _eventName = "LogCreateLoan(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(collateral, amt, debt, N);
    }

    /**
     * @dev Add collateral
     * @notice Add extra collateral to avoid bad liqidations
     * @param collateral collateral asset address
     * @param amt Amount of collateral to add
     * @param getId ID to retrieve amt.
     * @param setId ID stores the collateral amount of tokens added.
    */
    function addCollateral(
        address collateral,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        address _collateral = collateral == ethAddr ? wethAddr : collateral;
        IController controller = getController(_collateral);
        uint _amt = getUint(getId, amt);

        uint ethAmt;
        if (collateral == ethAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            ethAmt = _amt;
        } else {
            TokenInterface collateralContract = TokenInterface(_collateral);
            _amt = _amt == uint(-1) ? collateralContract.balanceOf(address(this)) : _amt;
            approve(collateralContract, address(controller), _amt);
        }

        controller.add_collateral{value: ethAmt}(_amt, address(this));

        setUint(setId, _amt);
        _eventName = "LogAddCollateral(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(collateral, amt, getId, setId);
    }

    /**
     * @dev Remove ETH/ERC20_Token Collateral.
     * @notice Remove some collateral without repaying the debt
     * @param collateral collateral asset address
     * @param amt Amount of collateral to add
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function removeCollateral(
        address collateral,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        address _collateral = collateral == ethAddr ? wethAddr : collateral;
        IController controller = getController(_collateral);
        uint _amt = getUint(getId, amt);

        controller.remove_collateral(_amt, collateral == ethAddr);

        setUint(setId, _amt);

        _eventName = "LogRemoveCollateral(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(collateral, amt, getId, setId);
    }

    /**
     * @dev Borrow more stablecoins while adding more collateral (not necessary)
     * @param collateral collateral token address
     * @param amt Amount of collateral to add
     * @param debt Amount of stablecoin debt to take
    */
    function borrowMore(
        address collateral,
        uint256 amt,
        uint256 debt
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        address _collateral = collateral == ethAddr ? wethAddr : collateral;
        IController controller = getController(_collateral);
        uint _amt = amt;

        uint ethAmt;
        if (collateral == ethAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            ethAmt = _amt;
        } else {
            TokenInterface collateralContract = TokenInterface(_collateral);
            _amt = _amt == uint(-1) ? collateralContract.balanceOf(address(this)) : _amt;
            approve(collateralContract, address(controller), _amt);
        }

        uint256[4] memory res = controller.user_state(address(this));
        uint256 _debt = debt == uint(-1) ? controller.max_borrowable(_amt + res[0], res[3]) - res[2] : debt;

        controller.borrow_more{value: ethAmt}(_amt, _debt);

        _eventName = "LogBorrowMore(address,uint256,uint256)";
        _eventParam = abi.encode(collateral, amt, debt);
    }

    /**
     * @dev Borrow DAI.
     * @notice Borrow DAI using a MakerDAO vault
     * @param collateral collateral token address
     * @param amt The amount of debt to repay. If higher than the current debt - will do full repayment
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of DAI borrowed.
    */
    function repay(
        address collateral,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        address _collateral = collateral == ethAddr ? wethAddr : collateral;
        IController controller = getController(_collateral);
        uint _amt = amt;

        TokenInterface stableCoin = TokenInterface(CRV_USD);
        _amt = _amt == uint(-1) ? stableCoin.balanceOf(address(this)) : _amt;
        TokenInterface collateralContract = TokenInterface(_collateral);
        approve(collateralContract, address(controller), _amt);

        controller.repay(_amt, address(this), 2**255-1, true);

        _eventName = "LogRepay(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(collateral, amt, getId, setId);
    }

    /**
     * @dev Peform a bad liquidation (or self-liquidation) of user if health is not good
     * @param collateral collateral token address
     * @param min_x Minimal amount of stablecoin to receive (to avoid liquidators being sandwiched)
    */
    function liquidate(
        address collateral,
        uint256 min_x
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        address _collateral = collateral == ethAddr ? wethAddr : collateral;
        IController controller = getController(_collateral);

        controller.liquidate(address(this), min_x, collateral == ethAddr);

        _eventName = "LogLiquidate(address,uint256)";
        _eventParam = abi.encode(collateral, min_x);
    }
}

contract ConnectV2CRV is MakerResolver {
    string public constant name = "CRV-USD-v1";
}