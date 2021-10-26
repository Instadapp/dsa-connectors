pragma solidity ^0.7.0;

interface PrizePoolInterface {
    function getToken() external view returns (address);
    function depositTo(address to, uint256 amount) external;
    function depositToAndDelegate(address to, uint256 amount, address delegate) external;
    function withdrawFrom(address from, uint256 amount) external returns (uint256);
}

interface TicketInterface {
    function delegate(address _to) external;
}

interface PrizeDistributorInterface {
    function claim(address user, uint32[] calldata drawIds, bytes calldata data) external returns (uint256);
}