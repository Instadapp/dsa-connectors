pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

interface InstaFlashV2Interface {
    function initiateFlashLoan(address token, uint256 amt, uint route, bytes calldata data) external;
    function initiateMultiFlashLoan(	
        address[] memory tokens_,	
        uint256[] memory amounts_,
        uint256,
        bytes calldata data	
    ) external;
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
}
