pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";

interface OneProtoInterface {
    function swap(
        TokenInterface fromToken,
        TokenInterface destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 flags // See contants in IOneSplit.sol
    ) external payable returns(uint256);

    function swapMulti(
        TokenInterface[] calldata tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256[] calldata flags
    ) external payable returns(uint256 returnAmount);

    function getExpectedReturn(
        TokenInterface fromToken,
        TokenInterface destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
    external
    view
    returns(
        uint256 returnAmount,
        uint256[] memory distribution
    );
}

interface OneProtoMappingInterface {
    function oneProtoAddress() external view returns(address);
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
