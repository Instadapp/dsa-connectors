pragma solidity ^0.7.0;

interface QiTokenInterface {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint); // For ARC20
    function liquidateBorrow(address borrower, uint repayAmount, address qiTokenCollateral) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function exchangeRateCurrent() external returns (uint);

    function balanceOf(address owner) external view returns (uint256 balance);
}

interface QiAVAXInterface {
    function mint() external payable;
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, address qiTokenCollateral) external payable;
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata qiTokens) external returns (uint[] memory);
    function exitMarket(address qiTokenAddress) external returns (uint);
    function getAssetsIn(address account) external view returns (address[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
    function claimReward(address) external;
}

interface BenqiMappingInterface {
    function qiTokenMapping(string calldata tokenId) external view returns (address);
    function getMapping(string calldata tokenId) external view returns (address, address);
}