//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Curve USD.
 * @dev Collateralized Borrowing.
 */

import { TokenInterface, AccountInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import "./interface.sol";

abstract contract CurveUSDResolver is Helpers, Events {
    /**
     * @dev Create loan
     * @dev If a user already has an existing loan, the function will revert.
     * @param collateral Collateral token address.(For ETH: `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`)
     * @param amount Amount of collateral (For max: `uint256(-1)`)
     * @param debt Stablecoin debt to take (For max: `uint256(-1)`)
     * @param numBands Number of bands to deposit into (to do autoliquidation-deliquidation), can only be from MIN_TICKS(4) to MAX_TICKS(50)
     * @param controllerVersion Controller version,
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of debt borrowed.
    */
    function createLoan(
        address collateral,
        uint256 amount,
        uint256 debt, 
        uint256 numBands,
        uint256 controllerVersion,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _amt = getUint(getId, amount);

        bool _isEth = collateral == ethAddr;
        address _collateralAddress = _isEth ? wethAddr : collateral;
        TokenInterface collateralContract = TokenInterface(_collateralAddress);
        
        // Get controller address of collateral.
        IController controller = getController(_collateralAddress, controllerVersion);

        if (_isEth) {
            _amt = _amt == uint256(-1) ? address(this).balance : _amt;
            convertEthToWeth(_isEth, collateralContract, _amt);
        } else {
            _amt = _amt == uint256(-1) ? collateralContract.balanceOf(address(this)) : _amt;
        }

        approve(collateralContract, address(controller), _amt);

        uint256 _debt = debt == uint256(-1) ? controller.max_borrowable(_amt, numBands) : debt;

        controller.create_loan(_amt, _debt, numBands);

        setUint(setId, _debt);
        _eventName = "LogCreateLoan(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(collateral, _amt, debt, numBands, getId, setId);
    }

    /**
     * @dev Add collateral
     * @notice Add extra collateral to avoid bad liqidations
     * @param collateral collateral asset address
     * @param version   controller version
     * @param amt Amount of collateral to add
     * @param getId ID to retrieve amt.
     * @param setId ID stores the collateral amount of tokens added.
    */
    function addCollateral(
        address collateral,
        uint256 version,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        address _collateral = collateral == ethAddr ? wethAddr : collateral;
        IController controller = getController(_collateral, version);
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
     * @param version   controller version
     * @param amt Amount of collateral to add
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function removeCollateral(
        address collateral,
        uint256 version,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        address _collateral = collateral == ethAddr ? wethAddr : collateral;
        IController controller = getController(_collateral, version);
        uint _amt = getUint(getId, amt);

        controller.remove_collateral(_amt, collateral == ethAddr);

        setUint(setId, _amt);

        _eventName = "LogRemoveCollateral(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(collateral, amt, getId, setId);
    }

    /**
     * @dev Borrow more stablecoins while adding more collateral (not necessary)
     * @param collateral collateral token address
     * @param version   controller version
     * @param amt Amount of collateral to add
     * @param debt Amount of stablecoin debt to take
    */
    function borrowMore(
        address collateral,
        uint256 version,
        uint256 amt,
        uint256 debt
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        address _collateral = collateral == ethAddr ? wethAddr : collateral;
        IController controller = getController(_collateral, version);
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
     * @param version   controller version
     * @param amt The amount of debt to repay. If higher than the current debt - will do full repayment
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of DAI borrowed.
    */
    function repay(
        address collateral,
        uint256 version,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        address _collateral = collateral == ethAddr ? wethAddr : collateral;
        IController controller = getController(_collateral, version);
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
     * @param version   controller version
     * @param min_x Minimal amount of stablecoin to receive (to avoid liquidators being sandwiched)
    */
    function liquidate(
        address collateral,
        uint256 version,
        uint256 min_x
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        address _collateral = collateral == ethAddr ? wethAddr : collateral;
        IController controller = getController(_collateral, version);

        controller.liquidate(address(this), min_x, collateral == ethAddr);

        _eventName = "LogLiquidate(address,uint256)";
        _eventParam = abi.encode(collateral, min_x);
    }
}

contract ConnectV2CurveUSD is CurveUSDResolver {
    string public constant name = "CurveUSD-v1.0";
}