pragma solidity ^0.6.5;

import { TokenInterface } from "../../common/interfaces.sol";

interface OneInchInterace {
    function swap(
        TokenInterface fromToken,
        TokenInterface toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        uint256 guaranteedAmount,
        address payable referrer,
        address[] calldata callAddresses,
        bytes calldata callDataConcat,
        uint256[] calldata starts,
        uint256[] calldata gasLimitsAndValues
    )
    external
    payable
    returns (uint256 returnAmount);
}

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