pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

interface InstaFlashV2Interface {
    function initiateFlashLoan(address[] calldata tokens, uint256[] calldata amts, uint route, bytes calldata data) external;
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
}