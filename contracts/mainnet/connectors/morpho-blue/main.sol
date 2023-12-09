//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./helpers.sol";
import "./events.sol";

abstract contract MorphoBlue is Helpers, Events {

	/**
	 * @dev Supply ETH/ERC20 Token for lending.
	 * @notice Supplies assets to Morpho Blue for lending.
	 * @param _marketParams The market to supply assets to. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _assets The amount of assets to supply.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function supply(
		MarketParams memory _marketParams,
        uint256 _assets,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		// Final assets amount and token contract
		(
			TokenInterface _tokenContract, // Loan token contract
			uint256 _amt
		) = _performEthToWethConversion(_marketParams, _assets, address(this), _getId, false, false);

		// Approving loan token for supplying
		approve(_tokenContract, address(MORPHO_BLUE), _amt);
		
		// Updating token addresses
		_marketParams.loanToken = address(_tokenContract);
		_marketParams.collateralToken = _marketParams.collateralToken == ethAddr ? wethAddr : _marketParams.collateralToken;

		(, uint256 _shares) = MORPHO_BLUE.supply(_marketParams, _amt, 0, address(this), new bytes(0));

		setUint(_setId, _amt);

		_eventName = "LogSupplyAssets(address,address,address,address,uint256,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_assets,
			_shares,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Supply ETH/ERC20 Token for lending.
	 * @notice Supplies assets to Morpho Blue for lending.
	 * @param _marketParams The market to supply assets to.(For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _assets The amount of assets to supply.
	 * @param _onBehalf The address that will get the shares.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function supplyOnBehalf(
		MarketParams memory _marketParams,
        uint256 _assets,
        address _onBehalf,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		// Final assets amount and token contract
		(
			TokenInterface _tokenContract, // Loan token contract
			uint256 _amt
		) = _performEthToWethConversion(_marketParams, _assets, _onBehalf, _getId, false, false);

		// Approving loan token for supplying
		approve(_tokenContract, address(MORPHO_BLUE), _amt);
		
		// Updating token addresses
		_marketParams.loanToken = address(_tokenContract);
		_marketParams.collateralToken = _marketParams.collateralToken == ethAddr ? wethAddr : _marketParams.collateralToken;

		(, uint256 _shares) = MORPHO_BLUE.supply(_marketParams, _amt, 0, _onBehalf, new bytes(0));

		setUint(_setId, _amt);

		_eventName = "LogSupplyAssetsOnBehalf(address,address,address,address,uint256,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_assets,
			_shares,
			_onBehalf,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Supply ETH/ERC20 Token for lending.
	 * @notice Supplies assets for a perfect share amount to Morpho Blue for lending.
	 * @param _marketParams The market to supply assets to. (For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _shares The amount of shares to mint.
	 * @param _onBehalf The address that will get the shares.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function supplySharesOnBehalf(
		MarketParams memory _marketParams,
        uint256 _shares,
        address _onBehalf,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		// Final converted assets amount for approval and token contract
		(
			TokenInterface _tokenContract, // Loan token contract
			uint256 _amt
		) = _performEthToWethSharesConversion(_marketParams, _shares, _onBehalf,  _getId, false);

		// Approving loan token for supplying
		approve(_tokenContract, address(MORPHO_BLUE), _amt);
		
		// Updating token addresses
		_marketParams.loanToken = address(_tokenContract);
		_marketParams.collateralToken = _marketParams.collateralToken == ethAddr ? wethAddr : _marketParams.collateralToken;

		(uint256 _assets, ) = MORPHO_BLUE.supply(_marketParams, _amt, _shares, _onBehalf, new bytes(0));

		setUint(_setId, _amt);

		_eventName = "LogSupplySharesOnBehalf(address,address,address,address,uint256,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_assets,
			_shares,
			_onBehalf,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Supply ETH/ERC20 Token for collateralization.
	 * @param _marketParams The market to supply assets to. (For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _assets The amount of assets to supply.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function supplyCollateral(
		MarketParams memory _marketParams,
        uint256 _assets,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		// Final assets amount and token contract
		(
			TokenInterface _tokenContract, // Collateral token contract
			uint256 _amt
		) = _performEthToWethConversion(_marketParams, _assets, address(this), _getId, true, false);

		// Approving collateral token
		approve(_tokenContract, address(MORPHO_BLUE), _amt);

		// Updating token addresses
		_marketParams.collateralToken = address(_tokenContract);
		_marketParams.loanToken = _marketParams.loanToken == ethAddr ? wethAddr : _marketParams.loanToken;

		MORPHO_BLUE.supplyCollateral(_marketParams, _amt, address(this), new bytes(0));

		setUint(_setId, _amt);

		_eventName = "LogSupplyCollateral(address,address,address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_assets,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Supplies `assets` of collateral on behalf of `onBehalf`, optionally calling back the caller's `onMorphoSupplyCollateral` function with the given `data`.
	 * @param _marketParams The market to supply assets to.(For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _assets The amount of assets to supply.
	 * @param _onBehalf The address that will get the shares.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function supplyCollateralOnBehalf(
		MarketParams memory _marketParams,
        uint256 _assets,
        address _onBehalf,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		// Final assets amount and token contract
		(
			TokenInterface _tokenContract, // Collateral token contract
			uint256 _amt
		) = _performEthToWethConversion(_marketParams, _assets, _onBehalf, _getId, true, false);

		// Approving collateral token
		approve(_tokenContract, address(MORPHO_BLUE), _amt);
		
		// Updating token addresses
		_marketParams.collateralToken = address(_tokenContract);
		_marketParams.loanToken = _marketParams.loanToken == ethAddr ? wethAddr : _marketParams.loanToken;

		MORPHO_BLUE.supplyCollateral(_marketParams, _amt, _onBehalf, new bytes(0));

		setUint(_setId, _amt);

		_eventName = "LogSupplyCollateralOnBehalf(address,address,address,address,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_assets,
			_onBehalf,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Handles the withdrawal of collateral by a user from a specific market of a specific amount.
	 * @dev The market to withdraw assets from. (For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams The market to withdraw assets from.
	 * @param _assets The amount of assets to withdraw.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function withdrawCollateral(
		MarketParams memory _marketParams,
        uint256 _assets,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _assets);

		// Updating token addresses
		bool _collateralIsEth = _marketParams.collateralToken == ethAddr;
		_marketParams.collateralToken = _collateralIsEth ? wethAddr : _marketParams.collateralToken;
		_marketParams.loanToken = _marketParams.loanToken == ethAddr ? wethAddr : _marketParams.loanToken;

		// If amount is max, fetch collateral value from Morpho's contract
		if (_assets == type(uint256).max) {
			bytes32 _id = id(_marketParams); 
			Position memory _pos = MORPHO_BLUE.position(_id, address(this));
			_amt = _pos.collateral;
		}

		MORPHO_BLUE.withdrawCollateral(_marketParams, _amt, address(this), address(this));

		convertWethToEth(_collateralIsEth, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogWithdrawCollateral(address,address,address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_amt,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Handles the withdrawal of collateral by a user from a specific market of a specific amount.
	 * @dev The market to withdraw assets from. (For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams The market to withdraw assets from.
	 * @param _assets The amount of assets to withdraw.
	 * @param _onBehalf The address that already deposited position.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function withdrawCollateralOnBehalf(
		MarketParams memory _marketParams,
        uint256 _assets,
        address _onBehalf,
		address _receiver,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _assets);

		// Updating token addresses
		bool _collateralIsEth = _marketParams.collateralToken == ethAddr;
		_marketParams.collateralToken = _collateralIsEth ? wethAddr : _marketParams.collateralToken;
		_marketParams.loanToken = _marketParams.loanToken == ethAddr ? wethAddr : _marketParams.loanToken;

		if (_amt == type(uint256).max) {
			bytes32 _id = id(_marketParams); 
			Position memory _pos = MORPHO_BLUE.position(_id, _onBehalf);
			_amt = _pos.collateral;
		}

		MORPHO_BLUE.withdrawCollateral(_marketParams, _amt, _onBehalf, _receiver);

		if(_receiver == address(this)) convertWethToEth(_collateralIsEth, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogWithdrawCollateralOnBehalf(address,address,address,address,uint256,uint256,address,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_amt,
			_onBehalf,
			_receiver,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Handles the withdrawal of supply.
	 * @dev  The market to withdraw assets from.(For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams The market to withdraw assets from.
	 * @param _assets The amount of assets to withdraw.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function withdraw(
		MarketParams memory _marketParams,
        uint256 _assets,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _assets);
		bool _isEth = _marketParams.loanToken == ethAddr;
		_marketParams.loanToken = _isEth ? wethAddr : _marketParams.loanToken;
		_marketParams.collateralToken = _marketParams.collateralToken == ethAddr ? wethAddr : _marketParams.collateralToken;

		if (_amt == type(uint256).max) {
			bytes32 _id = id(_marketParams); 
			Position memory _pos = MORPHO_BLUE.position(_id, address(this));
			uint256 _shares = _pos.supplyShares;
			_amt = _toAssetsUp(_shares, MORPHO_BLUE.market(_id).totalSupplyAssets, MORPHO_BLUE.market(_id).totalSupplyShares);
		}

		MORPHO_BLUE.withdraw(_marketParams, _amt, 0, address(this), address(this));

		convertWethToEth(_isEth, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogWithdraw(address,address,address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_amt,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Handles the withdrawal of a specified amount of assets by a user from a specific market.
	 * @dev The market to withdraw assets from. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams The parameters of the market.
	 * @param _assets The amount of assets the user is withdrawing.
	 * @param _onBehalf The address who's position to withdraw from.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function withdrawOnBehalf(
		MarketParams memory _marketParams,
        uint256 _assets,
        address _onBehalf,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _assets);
		_marketParams.loanToken = _marketParams.loanToken == ethAddr ? wethAddr : _marketParams.loanToken;
		_marketParams.collateralToken = _marketParams.collateralToken == ethAddr ? wethAddr : _marketParams.collateralToken;

		if (_amt == type(uint256).max) {
			bytes32 _id = id(_marketParams); 
			Position memory _pos = MORPHO_BLUE.position(_id, _onBehalf);
			uint256 _shares = _pos.supplyShares;
			_amt = _toAssetsUp(_shares, MORPHO_BLUE.market(_id).totalSupplyAssets, MORPHO_BLUE.market(_id).totalSupplyShares);
		}

		MORPHO_BLUE.withdraw(_marketParams, _amt, 0, _onBehalf, address(this));

		setUint(_setId, _amt);

		_eventName = "LogWithdrawOnBehalf(address,address,address,address,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_amt,
			_onBehalf,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Handles the withdrawal of a specified amount of assets by a user from a specific market.
	 * @dev The market to withdraw assets from. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams The parameters of the market.
	 * @param _shares The amount of shares the user is withdrawing.
	 * @param _onBehalf The address who's position to withdraw from.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function withdrawSharesOnBehalf(
		MarketParams memory _marketParams,
        uint256 _shares,
        address _onBehalf,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _shareAmt = getUint(_getId, _shares);
		_marketParams.loanToken = _marketParams.loanToken == ethAddr ? wethAddr : _marketParams.loanToken;
		_marketParams.collateralToken = _marketParams.collateralToken == ethAddr ? wethAddr : _marketParams.collateralToken;

		if (_shareAmt == type(uint256).max) {
			bytes32 _id = id(_marketParams); 
			Position memory _pos = MORPHO_BLUE.position(_id, _onBehalf);
			_shareAmt = _pos.supplyShares;
		}

		MORPHO_BLUE.withdraw(_marketParams, 0, _shareAmt, _onBehalf, address(this));

		setUint(_setId, _shareAmt);

		_eventName = "LogWithdrawSharesOnBehalf(address,address,address,address,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_shareAmt,
			_onBehalf,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Borrows assets.
	 * @dev The market to borrow assets from.(For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams The market to borrow assets from.
	 * @param _assets The amount of assets to borrow.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens borrowed.
	 */
	function borrow(
		MarketParams memory _marketParams,
        uint256 _assets,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _assets);
		bool _isETH = _marketParams.loanToken == ethAddr;

		_marketParams.loanToken = _isETH ? wethAddr : _marketParams.loanToken;
		_marketParams.collateralToken = _marketParams.collateralToken == ethAddr ? wethAddr : _marketParams.collateralToken;

		(, uint256 _shares) = MORPHO_BLUE.borrow(_marketParams, _amt, 0, address(this), address(this));

		convertWethToEth(_isETH, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogBorrow(address,address,address,address,uint256,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_amt,
			_shares,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Borrows `assets` on behalf of `onBehalf` to `receiver`.
	 * @dev The market to borrow assets from. (For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams  The market to borrow assets from.
	 * @param _assets The amount of assets to borrow.
	 * @param _onBehalf The address that will recieve the borrowing assets and own the borrow position.
	 * @param _receiver The address that will recieve the borrowed assets.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens borrowed.
	 */
	function borrowOnBehalf(
		MarketParams memory _marketParams,
        uint256 _assets,
        address _onBehalf,
		address _receiver,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _assets);
		bool _isETH = _marketParams.loanToken == ethAddr;

		_marketParams.loanToken = _isETH ? wethAddr : _marketParams.loanToken;
		_marketParams.collateralToken = _marketParams.collateralToken == ethAddr ? wethAddr : _marketParams.collateralToken;

		(, uint256 _shares) = MORPHO_BLUE.borrow(_marketParams, _amt, 0, _onBehalf, _receiver);

		if (_receiver == address(this)) convertWethToEth(_isETH, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogBorrowOnBehalf(address,address,address,address,uint256,uint256,uint256,address,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_amt,
			_shares,
			_onBehalf,
			_receiver,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Borrows `shares` on behalf of `onBehalf` to `receiver`.
	 * @dev The market to borrow assets from. (For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams The market to borrow assets from.
	 * @param _shares The amount of shares to mint.
	 * @param _onBehalf The address that will own the borrow position.
	 * @param _receiver The address that will recieve the borrowed assets.
	 * @param _getId ID to retrieve shares amt.
	 * @param _setId ID stores the amount of tokens borrowed.
	 */
	function borrowOnBehalfShares(
		MarketParams memory _marketParams,
        uint256 _shares,
        address _onBehalf,
		address _receiver,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _shareAmt = getUint(_getId, _shares);
		bool _isETH = _marketParams.loanToken == ethAddr;

		_marketParams.loanToken = _isETH ? wethAddr : _marketParams.loanToken;
		_marketParams.collateralToken = _marketParams.collateralToken == ethAddr ? wethAddr : _marketParams.collateralToken;

		(uint256 _assets, ) = MORPHO_BLUE.borrow(_marketParams, 0, _shareAmt, _onBehalf, _receiver);

		if (_receiver == address(this)) convertWethToEth(_isETH, TokenInterface(wethAddr), _assets);

		setUint(_setId, _assets);

		_eventName = "LogBorrowShares(address,address,address,address,uint256,uint256,uint256,address,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_assets,
			_shareAmt,
			_onBehalf,
			_receiver,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Repays assets.
	 * @dev The market to repay assets to. (For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams The market to repay assets to.
	 * @param _assets The amount of assets to repay.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens repaid.
	 */
	function repay(
		MarketParams memory _marketParams,
        uint256 _assets,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		// Final assets amount and token contract
		(
			TokenInterface _tokenContract,
			uint256 _amt // Assets final amount to repay
		) = _performEthToWethConversion(_marketParams, _assets, address(this), _getId, false, true);

		// Approving loan token for repaying
		approve(_tokenContract, address(MORPHO_BLUE), _amt);

		// Updating token addresses
		_marketParams.loanToken = address(_tokenContract);
		_marketParams.collateralToken = _marketParams.collateralToken == ethAddr ? wethAddr : _marketParams.collateralToken;

		(, uint256 _shares) = MORPHO_BLUE.repay(
			_marketParams, 
			_amt, 
			0, 
			address(this), 
			new bytes(0)
		);

		setUint(_setId, _amt);

		_eventName = "LogPayback(address,address,address,address,uint256,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_assets,
			_shares,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Repays assets on behalf.
	 * @dev The market to repay assets to. (For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams The market to repay assets to.
	 * @param _assets The amount of assets to repay.
	 * @param _onBehalf The address whose loan will be repaid.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens repaid.
	 */
	function repayOnBehalf(
		MarketParams memory _marketParams,
        uint256 _assets,
		address _onBehalf,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		// Final assets amount and token contract
		(
			TokenInterface _tokenContract,
			uint256 _amt // Assets final amount to repay
		) = _performEthToWethConversion(_marketParams, _assets, _onBehalf, _getId, false, true);

		// Approving loan token for repaying
		approve(_tokenContract, address(MORPHO_BLUE), _amt);

		// Updating token addresses
		_marketParams.loanToken = address(_tokenContract);
		_marketParams.collateralToken = _marketParams.collateralToken == ethAddr ? wethAddr : _marketParams.collateralToken;

		(, uint256 _shares) = MORPHO_BLUE.repay(
			_marketParams, 
			_amt, 
			0, 
			_onBehalf, 
			new bytes(0)
		);

		setUint(_setId, _amt);

		_eventName = "LogPaybackOnBehalf(address,address,address,address,uint256,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_assets,
			_shares,
			_onBehalf,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Repays shares on behalf.
	 * @dev The market to repay assets to. (For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams The market to repay assets to.
	 * @param _shares The amount of shares to burn.
	 * @param _onBehalf The address whose loan will be repaid.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens repaid.
	 */
	function repayOnBehalfShares(
		MarketParams memory _marketParams,
        uint256 _shares,
		address _onBehalf,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		// Final assets amount and token contract
		(
			TokenInterface _tokenContract,
			uint256 _assetsAmt // Assets final amount to repay
		) = _performEthToWethSharesConversion(_marketParams, _shares, _onBehalf, _getId, true);

		approve(_tokenContract, address(MORPHO_BLUE), _assetsAmt);

		(uint256 _assets, ) = MORPHO_BLUE.repay(
			_marketParams, 
			_assetsAmt, 
			0, 
			_onBehalf, 
			new bytes(0)
		);

		setUint(_setId, _assets);

		_eventName = "LogPaybackShares(address,address,address,address,uint256,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_marketParams.collateralToken,
			_marketParams.oracle,
			_marketParams.irm,
			_marketParams.lltv,
			_assets,
			_shares,
			_onBehalf,
			_getId,
			_setId
		);
	}
}

contract ConnectV2MorphoBlue is MorphoBlue {
	string public constant name = "Morpho-Blue-v1.0";
}
