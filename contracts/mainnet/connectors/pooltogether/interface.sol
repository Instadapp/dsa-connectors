pragma solidity ^0.7.0;

interface PrizePoolInterface {
    function depositTo( address to, uint256 amount, address controlledToken, address referrer) external;
    function withdrawInstantlyFrom( address from, uint256 amount, address controlledToken, uint256 maximumExitFee) external returns (uint256);
}