pragma solidity ^0.6.0;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface EventInterface {
    function emitEvent(uint connectorType, uint connectorID, bytes32 eventCode, bytes calldata eventData) external;
}

struct OneProtoData {
    TokenInterface sellToken;
    TokenInterface buyToken;
    uint _sellAmt;
    uint _buyAmt;
    uint unitAmt;
    uint[] distribution;
    uint disableDexes;
}

struct OneProtoMultiData {
    address[] tokens;
    TokenInterface sellToken;
    TokenInterface buyToken;
    uint _sellAmt;
    uint _buyAmt;
    uint unitAmt;
    uint[] distribution;
    uint[] disableDexes;
}

struct OneInchData {
    TokenInterface sellToken;
    TokenInterface buyToken;
    uint _sellAmt;
    uint _buyAmt;
    uint unitAmt;
    bytes callData;
}