pragma solidity ^0.7.0;

contract Events {
    event LogCreate(address _tokenFrom, address _tokenTo, uint256 _price, uint32 _route, bytes8 _pos);
    event LogCancel(address _tokenFrom, address _tokenTo, bytes8 _orderId);
    event LogCancelPublic(address _tokenFrom, address _tokenTo, bytes8 _orderId);
    event LogSell(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );
}
