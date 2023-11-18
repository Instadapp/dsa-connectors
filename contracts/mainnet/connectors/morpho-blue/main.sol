//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./helpers.sol";
import "./events.sol";

abstract contract MorphoBlue is Helpers, Events {

	/// @notice Creates the market `marketParams`.
	/// @param marketParams The market to supply assets to.
	function createMarket(MarketParams memory marketParams) external {
		MORPHO_BLUE.createMarket(marketParams);
	}

	/**
	 * @dev Supplying a large amount can revert for overflow.
	 * @notice Supplies `assets` or `shares` on behalf of `onBehalf`, optionally calling back the caller's `onMorphoSupply` function with the given `data`.
	 * @param _marketParams The market to supply assets to.(For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _assets The amount of assets to supply.
	 * @param _shares The amount of shares to mint.
	 * @param _data Arbitrary data to pass to the `onMorphoSupply` callback. Pass empty data if not needed.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function supply(
		MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _shares,
        bytes calldata _data,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(
			TokenInterface _tokenContract,
			uint256 _amt,
		) = _performEthToWethConversion(_marketParams.loanToken, _assets, _getId);
			 
		bytes32 _id = id(_marketParams);
		uint256 _approveAmount = _getApproveAmount(_id, _amt, _shares);
		approve(_tokenContract, address(MORPHO_BLUE), _approveAmount);
		_marketParams.loanToken = address(_tokenContract);

		(_assets, _shares) = MORPHO_BLUE.supply(_marketParams, _amt, _shares, address(this), _data);

		setUint(_setId, _amt);

		_eventName = "LogSupply(address,uint256,uint256,address,bytes,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_assets,
			_shares,
			address(this),
			_data,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Supplying a large amount can revert for overflow.
	 * @notice Supplies `assets` or `shares` on behalf of `onBehalf`, optionally calling back the caller's `onMorphoSupply` function with the given `data`.
	 * @param _marketParams 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE native token is not allowed in this mode cause of failing in withdraw of WETH.
	 * @param _assets The amount of assets to supply.
	 * @param _shares The amount of shares to mint.
	 * @param _onBehalf The address that will own the increased supply position.
	 * @param _data Arbitrary data to pass to the `onMorphoSupply` callback. Pass empty data if not needed.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function supplyOnBehalf(
		MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _shares,
        address _onBehalf,
        bytes calldata _data,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _assets);

		bytes32 _id = id(_marketParams);
		uint256 _approveAmount = _getApproveAmount(_id, _amt, _shares);
		approve(TokenInterface(_marketParams.loanToken), address(MORPHO_BLUE), _approveAmount);

		(_assets, _shares) = MORPHO_BLUE.supply(_marketParams, _amt, _shares, _onBehalf, _data);

		setUint(_setId, _amt);

		_eventName = "LogSupply(address,uint256,uint256,address,bytes,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_assets,
			_shares,
			_onBehalf,
			_data,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Supplies `assets` of collateral on behalf of `onBehalf`, optionally calling back the caller's `onMorphoSupplyCollateral` function with the given `data`.
	 * @param _marketParams The market to supply assets to.(For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _assets The amount of assets to supply.
	 * @param _data Arbitrary data to pass to the `onMorphoSupply` callback. Pass empty data if not needed.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function supplyCollateral(
		MarketParams memory _marketParams,
        uint256 _assets,
        bytes calldata _data,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(
			TokenInterface _tokenContract,
			uint256 _amt,
		) = _performEthToWethConversion(_marketParams.loanToken, _assets, _getId);

		approve(_tokenContract, address(MORPHO_BLUE), _amt);
		_marketParams.loanToken = address(_tokenContract);

		MORPHO_BLUE.supplyCollateral(_marketParams, _amt, address(this), _data);

		setUint(_setId, _amt);

		_eventName = "LogSupplyCollateral(address,uint256,address,bytes,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_assets,
			address(this),
			_data,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Supplies `assets` of collateral on behalf of `onBehalf`, optionally calling back the caller's `onMorphoSupplyCollateral` function with the given `data`.
	 * @param _marketParams 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE native token is not allowed in this mode cause of failing in withdraw of WETH.
	 * @param _assets The amount of assets to supply.
	 * @param _onBehalf The address that will own the increased supply position.
	 * @param _data Arbitrary data to pass to the `onMorphoSupply` callback. Pass empty data if not needed.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function supplyCollateralOnBehalf(
		MarketParams memory _marketParams,
        uint256 _assets,
        address _onBehalf,
        bytes calldata _data,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _assets);

		approve(TokenInterface(_marketParams.loanToken), address(MORPHO_BLUE), _amt);

		MORPHO_BLUE.supplyCollateral(_marketParams, _amt, _onBehalf, _data);

		setUint(_setId, _amt);

		_eventName = "LogSupplyCollateral(address,uint256,address,bytes,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_assets,
			_onBehalf,
			_data,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Supplies `assets` or `shares` on behalf of `onBehalf`, optionally calling back the caller's `onMorphoSupply` function with the given `data`.
	 * @dev Supplying a large amount can revert for overflow.
	 * @dev 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE native token is not allowed in this mode cause of failing in withdraw of WETH.
	 * @param _marketParams The market to supply assets to.
	 * @param _assets The amount of assets to supply.
	 * @param _onBehalf The address that already deposited position.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function withdrawCollateralOnBehalf(
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
		if (_amt == uint256(-1)) {
			bytes32 _id = id(_marketParams); 
			Position memory _pos = MORPHO_BLUE.position(_id, _onBehalf);
			_amt = _pos.collateral;
		}

		MORPHO_BLUE.withdrawCollateral(_marketParams, _amt, _onBehalf, address(this));

		setUint(_setId, _amt);

		_eventName = "LogWithdrawCollateral(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_amt,
			_onBehalf,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Supplies `assets` or `shares` on behalf of `onBehalf`, optionally calling back the caller's `onMorphoSupply` function with the given `data`.
	 * @dev Supplying a large amount can revert for overflow.
	 * @dev  The market to supply assets to.(For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams The market to supply assets to.
	 * @param _assets The amount of assets to supply.
	 * @param _shares The amount of shares to mint.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function withdrawCollateral(
		MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _shares,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt;
		(
			TokenInterface _tokenContract,
			,
			bool _isMax
		) = _performEthToWethConversion(_marketParams.loanToken, _assets, _getId);
		if (_isMax) {
			bytes32 _id = id(_marketParams); 
			Position memory _pos = MORPHO_BLUE.position(_id, address(this));
			_amt = _pos.collateral;
		}
		address originToken = _marketParams.loanToken;
		_marketParams.loanToken = address(_tokenContract);

		MORPHO_BLUE.withdrawCollateral(_marketParams, _amt, address(this), address(this));

		convertWethToEth(originToken == ethAddr, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogWithdraw(address,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_amt,
			_shares,
			address(this),
			_getId,
			_setId
		);
	}

	/**
	 * @notice Supplies `assets` or `shares` on behalf of `onBehalf`, optionally calling back the caller's `onMorphoSupply` function with the given `data`.
	 * @dev Supplying a large amount can revert for overflow.
	 * @dev 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE native token is not allowed in this mode cause of failing in withdraw of WETH.
	 * @param _marketParams The market to supply assets to.
	 * @param _assets The amount of assets to supply.
	 * @param _shares The amount of shares to mint.
	 * @param _onBehalf The address that already deposited position.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function withdrawOnBehalf(
		MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _shares,
        address _onBehalf,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{

		uint256 _amt = getUint(_getId, _assets);
		bool _isMax;
		if (_amt == uint256(-1)) {
			_amt = TokenInterface(_marketParams.loanToken).balanceOf(_onBehalf);
			_isMax = true;
		}

		MORPHO_BLUE.withdraw(_marketParams, (_isMax ? 0 : _amt), (_isMax ? _amt : _shares), _onBehalf, address(this));

		setUint(_setId, _amt);

		_eventName = "LogWithdraw(address,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_amt,
			_shares,
			_onBehalf,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Supplies `assets` or `shares` on behalf of `onBehalf`, optionally calling back the caller's `onMorphoSupply` function with the given `data`.
	 * @dev Supplying a large amount can revert for overflow.
	 * @dev  The market to supply assets to.(For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams The market to supply assets to.
	 * @param _assets The amount of assets to supply.
	 * @param _shares The amount of shares to mint.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function withdraw(
		MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _shares,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{

		(
			TokenInterface _tokenContract,
			uint256 _amt,
			bool _isMax
		) = _performEthToWethConversion(_marketParams.loanToken, _assets, _getId);
		address originToken = _marketParams.loanToken;
		_marketParams.loanToken = address(_tokenContract);

		(_assets, _shares) = MORPHO_BLUE.withdraw(_marketParams, (_isMax ? 0 : _amt), (_isMax ? _amt : _shares), address(this), address(this));

		convertWethToEth(originToken == ethAddr, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogWithdraw(address,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_amt,
			_shares,
			address(this),
			_getId,
			_setId
		);
	}

	/**
	 * @notice Borrows `assets` or `shares` on behalf of `onBehalf` to `receiver`. receiver should be address(this)
	 * @dev 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE native token is not allowed in this mode cause of failing in withdraw of WETH.
	 * @param _marketParams The market to supply assets to.
	 * @param _assets The amount of assets to supply.
	 * @param _shares The amount of shares to mint.
	 * @param _onBehalf The address that will own the borrow position.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens borrowed.
	 */
	function borrowOnBehalf(
		MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _shares,
        address _onBehalf,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _assets);

		(_assets, _shares) = MORPHO_BLUE.borrow(_marketParams, _amt, _shares, _onBehalf, address(this));

		setUint(_setId, _amt);

		_eventName = "LogBorrow(address,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_assets,
			_shares,
			_onBehalf,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Borrows `assets` or `shares`. receiver should be address(this)
	 * @dev The market to supply assets to.(For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams The market to supply assets to.
	 * @param _assets The amount of assets to supply.
	 * @param _shares The amount of shares to mint.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens borrowed.
	 */
	function borrow(
		MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _shares,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(
			TokenInterface _tokenContract,
			uint256 _amt,
		) = _performEthToWethConversion(_marketParams.loanToken, _assets, _getId);

		address _oldLoanToken =  _marketParams.loanToken;
		_marketParams.loanToken = address(_tokenContract);

		(_assets, _shares) = MORPHO_BLUE.borrow(_marketParams, _amt, _shares, address(this), address(this));

		convertWethToEth(_oldLoanToken == ethAddr, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogBorrow(address,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_assets,
			_shares,
			address(this),
			_getId,
			_setId
		);
	}

	/**
	 * @notice Repays `assets` or `shares`.
	 * @dev The market to supply assets to.(For ETH of loanToken in _marketParams: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _marketParams The market to supply assets to.
	 * @param _assets The amount of assets to supply.
	 * @param _shares The amount of shares to mint.
	 * @param _data Arbitrary data to pass to the `onMorphoRepay` callback. Pass empty data if not needed.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens borrowed.
	 */
	function repay(
		MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _shares,
        bytes memory _data,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(
			TokenInterface _tokenContract,
			uint256 _amt,
			bool _isMax
		) = _performEthToWethConversion(_marketParams.loanToken, _assets, _getId);

		address _oldLoanToken =  _marketParams.loanToken;
		_marketParams.loanToken = address(_tokenContract);

		if (_isMax) {
			_assets = 0;
			_shares = _amt;
		} else {
			_assets = _amt;
		}
		{
			bytes32 _id = id(_marketParams);
			uint256 _approveAmount = _getApproveAmount(_id, _assets, _shares);

			approve(TokenInterface(_marketParams.loanToken), address(MORPHO_BLUE), _approveAmount);
		}


		(_assets, _shares) = MORPHO_BLUE.repay(
			_marketParams, 
			_assets, 
			_shares, 
			address(this), 
			_data
		);

		convertWethToEth(_oldLoanToken == ethAddr, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogPayback(address,uint256,uint256,address,bytes,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_assets,
			_shares,
			address(this),
			_data,
			_getId,
			_setId
		);
	}

	/**
	 * @notice Repays `assets` or `shares` on behalf of `onBehalf`, optionally calling back the caller's `onMorphoReplay` function with the given `data`.
	 * @dev 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE native token is not allowed in this mode cause of failing in withdraw of WETH.
	 * @param _marketParams The market to supply assets to.
	 * @param _assets The amount of assets to supply.
	 * @param _shares The amount of shares to mint.
	 * @param _onBehalf The address that will own the borrow position.
	 * @param _data Arbitrary data to pass to the `onMorphoRepay` callback. Pass empty data if not needed.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens borrowed.
	 */
	function repayOnBehalf(
		MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _shares,
		address _onBehalf,
        bytes memory _data,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _assets);
		bool _isMax;
		if (_amt == uint256(-1)) {
			_amt = TokenInterface(_marketParams.loanToken).balanceOf(_onBehalf);
			_isMax = true;
		}

		if (_isMax) {
			_assets = 0;
			_shares = _amt;
		} else {
			_assets = _amt;
		}

		bytes32 _id = id(_marketParams);
		uint256 _approveAmount = _getApproveAmount(_id, _assets, _shares);

		approve(TokenInterface(_marketParams.loanToken), address(MORPHO_BLUE), _approveAmount);

		(_assets, _shares) = MORPHO_BLUE.repay(
			_marketParams, 
			_assets, 
			_shares, 
			address(this), 
			_data
		);

		setUint(_setId, _amt);

		_eventName = "LogPayback(address,uint256,uint256,address,bytes,uint256,uint256)";
		_eventParam = abi.encode(
			_marketParams.loanToken,
			_assets,
			_shares,
			address(this),
			_data,
			_getId,
			_setId
		);
	}
}

contract ConnectV2MorphoBlue is MorphoBlue {
	string public constant name = "Morpho-Blue-v1.0";
}
