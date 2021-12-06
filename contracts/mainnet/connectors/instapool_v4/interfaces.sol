pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

interface InstaFlashV4Interface {
    function flashLoan(address[] memory tokens, uint256[] memory amts, uint route, bytes memory data, bytes memory extraData) external;
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
}
