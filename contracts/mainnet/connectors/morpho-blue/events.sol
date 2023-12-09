//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./interface.sol";

contract Events {

	event LogSupplyAssets(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 assets,
        uint256 shares,
		uint256 getId,
		uint256 setId
	);

	event LogSupplyAssetsOnBehalf(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 assets,
        uint256 shares,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogSupplySharesOnBehalf(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 assets,
        uint256 shares,
        address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogSupplyCollateral(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 assets,
		uint256 getId,
		uint256 setId
	);

	event LogSupplyCollateralOnBehalf(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 assets,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogBorrow(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 amounts,
		uint256 shares,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowOnBehalf(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 amounts,
		uint256 shares,
		address onBehalf,
		address reciever,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowShares(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 amounts,
		uint256 shares,
		address onBehalf,
		address reciever,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 amounts,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawOnBehalf(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 amounts,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawSharesOnBehalf(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 shares,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawCollateral(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 amounts,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawCollateralOnBehalf(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 amounts,
		address onBehalf,
		address reciever,
		uint256 getId,
		uint256 setId
	);

	event LogPayback(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 amounts,
		uint256 shares,
		uint256 getId,
		uint256 setId
	);

	event LogPaybackOnBehalf(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 amounts,
		uint256 shares,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogPaybackShares(
		address loanToken,
		address collateralToken,
		address oracle,
		address irm,
		uint256 lltv,
		uint256 amounts,
		uint256 shares,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);
}
