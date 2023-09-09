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
        _eventName = "LogCreateLoan(address,uint256,uint256,uint256,uint256,uin256,uin256)";
        _eventParam = abi.encode(collateral, _amt, debt, numBands, controllerVersion, getId, setId);
    }

    /**
     * @dev Add collateral
     * @notice Add extra collateral to avoid bad liqidations
     * @param collateral Collateral token address.(For ETH: `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`)
     * @param amt Amount of collateral (For max: `uint256(-1)`)
     * @param controllerVersion Controller version,
     * @param getId ID to retrieve amt.
     * @param setId ID stores the collateral amount of tokens added.
    */
    function addCollateral(
        address collateral,
        uint256 amt,
        uint256 controllerVersion,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        bool _isEth = collateral == ethAddr;
        address _collateralAddress = _isEth ? wethAddr : collateral;
        IController controller = getController(_collateralAddress, controllerVersion);
        TokenInterface collateralContract = TokenInterface(_collateralAddress);
        uint _amt = getUint(getId, amt);

        uint ethAmt;
        if (_isEth) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            ethAmt = _amt;
            convertEthToWeth(_isEth, collateralContract, _amt);
        } else {
            _amt = _amt == uint(-1) ? collateralContract.balanceOf(address(this)) : _amt;
        }

        approve(collateralContract, address(controller), _amt);
        controller.add_collateral(_amt, address(this));

        setUint(setId, _amt);
        _eventName = "LogAddCollateral(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(collateral, amt, controllerVersion, getId, setId);
    }

    /**
     * @dev Remove ETH/ERC20_Token Collateral.
     * @notice Remove some collateral without repaying the debt
     * @param collateral Collateral token address.(For ETH: `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`)
     * @param amt Remove collateral amount (For max: `uint256(-1)`)
     * @param controllerVersion   controller version
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function removeCollateral(
        address collateral,
        uint256 amt,
        uint256 controllerVersion,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        bool _isEth = collateral == ethAddr;
        address _collateralAddress = _isEth ? wethAddr : collateral;
        IController controller = getController(_collateralAddress, controllerVersion);
        uint _amt = getUint(getId, amt);

        controller.remove_collateral(_amt, collateral == ethAddr);

        setUint(setId, _amt);

        _eventName = "LogRemoveCollateral(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(collateral, amt, controllerVersion, getId, setId);
    }

    /**
     * @dev Borrow more stablecoins while adding more collateral (not necessary)
     * @param collateral Collateral token address.(For ETH: `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`)
     * @param amt Collateral amount for borrow more (For max: `uint256(-1)`)
     * @param debt Stablecoin debt to take for borrow more (For max: `uint256(-1)`)
     * @param controllerVersion controller version
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function borrowMore(
        address collateral,
        uint256 amt,
        uint256 debt,
        uint256 controllerVersion,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        bool _isEth = collateral == ethAddr;
        address _collateralAddress = _isEth ? wethAddr : collateral;
        IController controller = getController(_collateralAddress, controllerVersion);
        TokenInterface collateralContract = TokenInterface(_collateralAddress);
        uint _amt = getUint(getId, amt);

        uint ethAmt;
        if (_isEth) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            ethAmt = _amt;
            convertEthToWeth(_isEth, collateralContract, _amt);
        } else {
            _amt = _amt == uint(-1) ? collateralContract.balanceOf(address(this)) : _amt;
        }
        
        approve(collateralContract, address(controller), _amt);

        uint256[4] memory res = controller.user_state(address(this));
        uint256 _debt = debt == uint(-1) ? controller.max_borrowable(_amt + res[0], res[3]) - res[2] : debt;

        controller.borrow_more(_amt, _debt);
        
        setUint(setId, _amt);
        _eventName = "LogBorrowMore(address,uint256,uint256,uint256,uin256,uin256)";
        _eventParam = abi.encode(collateral, amt, debt, controllerVersion, getId, setId);
    }

    /**
     * @dev Repay Curve-USD.
     * @param collateral Collateral token address.(For ETH: `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`)
     * @param amt repay amount (For max: `uint256(-1)`)
     * @param controllerVersion Controller version,
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of debt borrowed.
    */
    function repay(
        address collateral,
        uint256 amt,
        uint256 controllerVersion,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        bool _isEth = collateral == ethAddr;
        address _collateralAddress = _isEth ? wethAddr : collateral;
        IController controller = getController(_collateralAddress, controllerVersion);
        uint _amt = getUint(getId, amt);

        TokenInterface stableCoin = TokenInterface(CRV_USD);
        _amt = _amt == uint(-1) ? stableCoin.balanceOf(address(this)) : _amt;

        approve(stableCoin, address(controller), _amt);

        controller.repay(_amt);

        setUint(setId, _amt);
        _eventName = "LogRepay(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(collateral, amt, controllerVersion, getId, setId);
    }

    /**
     * @dev Peform a bad liquidation (or self-liquidation) of user if health is not good
     * @param collateral collateral token address
     * @param min_x Minimal amount of stablecoin to receive (to avoid liquidators being sandwiched)
     * @param controllerVersion   controller version
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of debt borrowed. 
    */
    function liquidate(
        address collateral,
        uint256 min_x,
        uint256 controllerVersion,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        bool _isEth = collateral == ethAddr;
        address _collateralAddress = _isEth ? wethAddr : collateral;
        IController controller = getController(_collateralAddress, controllerVersion);
        uint _min_x = getUint(getId, min_x);

        controller.liquidate(address(this), _min_x, _isEth);

        setUint(setId, _min_x);
        _eventName = "LogLiquidate(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(collateral, _min_x, controllerVersion, getId, setId);
    }
}

contract ConnectV2CurveUSD is CurveUSDResolver {
    string public constant name = "CurveUSD-v1.0";
}