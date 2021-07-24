pragma solidity ^0.7.0;


interface LimitOrderInterface {
    function create(address _tokenFrom, address _tokenTo, uint128 _price, uint32 _route, bytes8 _pos) external;
    function create(address _tokenFrom, address _tokenTo, uint128 _price, uint32 _route) external;
    function sell(address _tokenFrom, address _tokenTo, uint _amountFrom, bytes8 _orderId, address _to) external returns (uint _amountTo);
    function sell(
        address _tokenFrom,
        address _tokenTo,
        uint _amountFrom,
        bytes8[] memory _orderIds,
        uint[] memory _distributions,
        uint _units,
        address _to
    ) external returns (uint _amountTo);
    function cancel(address _tokenFrom, address _tokenTo, bytes8 _orderId) external;
    function cancelPublic(address _tokenFrom, address _tokenTo, bytes8 _orderId) external;
}