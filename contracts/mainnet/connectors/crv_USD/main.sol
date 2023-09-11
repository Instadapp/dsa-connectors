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
     * @param amt Amount of collateral (For max: `uint256(-1)`)
     * @param debtAmt Stablecoin debt to take (For max: `uint256(-1)`)
     * @param numBands Number of bands to deposit into (to do autoliquidation-deliquidation), can only be from MIN_TICKS(4) to MAX_TICKS(50)
     * @param controllerVersion Controller version,
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of debt borrowed.
    */
    function createLoan(
        address collateral,
        uint256 amt,
        uint256 debtAmt, 
        uint256 numBands,
        uint256 controllerVersion,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _amt = getUint(getId, amt);

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

        uint256 _debtAmt = debtAmt == uint256(-1) ? controller.max_borrowable(_amt, numBands) : debtAmt;

        controller.create_loan(_amt, _debtAmt, numBands);

        setUint(setId, _debtAmt);
        _eventName = "LogCreateLoan(address,uint256,uint256,uint256,uint256,uin256,uin256)";
        _eventParam = abi.encode(collateral, _amt, _debtAmt, numBands, controllerVersion, getId, setId);
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
        uint _amt = getUint(getId, amt);
        
        bool _isEth = collateral == ethAddr;
        address _collateralAddress = _isEth ? wethAddr : collateral;

        // Get controller address of collateral.
        IController controller = getController(_collateralAddress, controllerVersion);
        TokenInterface collateralContract = TokenInterface(_collateralAddress);

        if (_isEth) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
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
        uint _amt = getUint(getId, amt);

        bool _isEth = collateral == ethAddr;
        address _collateralAddress = _isEth ? wethAddr : collateral;

        IController controller = getController(_collateralAddress, controllerVersion);

        // remove_collateral will unwrap the eth.
        controller.remove_collateral(_amt, _isEth);

        setUint(setId, _amt);
        _eventName = "LogRemoveCollateral(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(collateral, amt, controllerVersion, getId, setId);
    }

    /**
     * @dev Borrow more stablecoins while adding more collateral (not necessary)
     * @param collateral Collateral token address.(For ETH: `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`)
     * @param debtAmt Stablecoin debt to take for borrow more (For max: `uint256(-1)`)
     * @param controllerVersion controller version
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function borrowMore(
        address collateral,
        uint256 debtAmt,
        uint256 controllerVersion,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, debtAmt);

        bool _isEth = collateral == ethAddr;

        address _collateralAddress = _isEth ? wethAddr : collateral;
        IController controller = getController(_collateralAddress, controllerVersion);

        uint256[4] memory res = controller.user_state(address(this));
        uint256 _debtAmt = debtAmt == uint(-1) 
            ? controller.max_borrowable(res[0], res[3]) - res[2] 
            : debtAmt;

        controller.borrow_more(0, _debtAmt);
        
        setUint(setId, _amt);
        _eventName = "LogBorrowMore(address,uint256,uint256,uin256,uin256)";
        _eventParam = abi.encode(collateral, debtAmt, controllerVersion, getId, setId);
    }

    /**
     * @dev Borrow more stablecoins while adding more collateral (not necessary)
     * @param collateral Collateral token address.(For ETH: `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`)
     * @param colAmt Collateral amount for borrow more (For max: `uint256(-1)`)
     * @param debtAmt Stablecoin debt to take for borrow more (For max: `uint256(-1)`)
     * @param controllerVersion controller version
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function addCollateralAndBorrowMore(
        address collateral,
        uint256 colAmt,
        uint256 debtAmt,
        uint256 controllerVersion,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, colAmt);

        bool _isEth = collateral == ethAddr;
        address _collateralAddress = _isEth ? wethAddr : collateral;
        TokenInterface collateralContract = TokenInterface(_collateralAddress);

        IController controller = getController(_collateralAddress, controllerVersion);

        if (_isEth) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            convertEthToWeth(_isEth, collateralContract, _amt);
        } else {
            _amt = _amt == uint(-1) ? collateralContract.balanceOf(address(this)) : _amt;
        }
        
        approve(collateralContract, address(controller), _amt);

        uint256[4] memory res = controller.user_state(address(this));
        uint256 _debtAmt = debtAmt == uint(-1) 
            ? controller.max_borrowable(_amt + res[0], res[3]) - res[2] 
            : debtAmt;

        controller.borrow_more(_amt, _debtAmt);
        
        setUint(setId, _amt);
        _eventName = "LogAddCollateralAndBorrowMore(address,uint256,uint256,uint256,uin256,uin256)";
        _eventParam = abi.encode(collateral, colAmt, debtAmt, controllerVersion, getId, setId);
    }

    /**
     * @dev Repay Curve-USD.
     * @param collateral Collateral token address.(For ETH: `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`)
     * @param amt repay amount (For max: `uint256(-1)`)
     * @param controllerVersion Controller version.
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
        uint _amt = getUint(getId, amt);

        bool _isEth = collateral == ethAddr;
        address _collateralAddress = _isEth ? wethAddr : collateral;
        IController controller = getController(_collateralAddress, controllerVersion);

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
     * @param minReceiveAmt Minimal amount of stablecoin to receive (to avoid liquidators being sandwiched)
     * @param controllerVersion controller version.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of debt borrowed. 
    */
    function selfLiquidate(
        address collateral,
        uint256 minReceiveAmt,
        uint256 controllerVersion,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _minReceiveAmt = getUint(getId, minReceiveAmt);

        bool _isEth = collateral == ethAddr;
        address _collateralAddress = _isEth ? wethAddr : collateral;
        IController controller = getController(_collateralAddress, controllerVersion);

        TokenInterface stableCoin = TokenInterface(CRV_USD);
        approve(stableCoin, address(controller), _minReceiveAmt);

        controller.liquidate(address(this), _minReceiveAmt, _isEth);

        setUint(setId, _minReceiveAmt);
        _eventName = "LogLiquidate(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(collateral, _minReceiveAmt, controllerVersion, getId, setId);
    }
}

contract ConnectV2CurveUSD is CurveUSDResolver {
    string public constant name = "CurveUSD-v1.0";
}