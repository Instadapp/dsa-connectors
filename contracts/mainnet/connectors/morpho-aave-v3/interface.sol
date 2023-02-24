//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IMorphoCore {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

	function supply(address underlying, uint256 amount, address onBehalf, uint256 maxIterations)
        external
        returns (uint256 supplied);

    function supplyWithPermit(
        address underlying,
        uint256 amount,
        address onBehalf,
        uint256 maxIterations,
        uint256 deadline,
        Signature calldata signature
    ) external returns (uint256 supplied);

    function supplyCollateral(address underlying, uint256 amount, address onBehalf)
        external
        returns (uint256 supplied);
		
    function supplyCollateralWithPermit(
        address underlying,
        uint256 amount,
        address onBehalf,
        uint256 deadline,
        Signature calldata signature
    ) external returns (uint256 supplied);

    function borrow(address underlying, uint256 amount, address onBehalf, address receiver, uint256 maxIterations)
        external
        returns (uint256 borrowed);

    function repay(address underlying, uint256 amount, address onBehalf) external returns (uint256 repaid);

    function repayWithPermit(
        address underlying,
        uint256 amount,
        address onBehalf,
        uint256 deadline,
        Signature calldata signature
    ) external returns (uint256 repaid);

    function withdraw(address underlying, uint256 amount, address onBehalf, address receiver, uint256 maxIterations)
        external
        returns (uint256 withdrawn);

    function withdrawCollateral(address underlying, uint256 amount, address onBehalf, address receiver)
        external
        returns (uint256 withdrawn);
}
