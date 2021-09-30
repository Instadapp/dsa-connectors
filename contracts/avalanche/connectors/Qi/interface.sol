pragma solidity ^0.7.0;

interface ComptrollerInterface {
    function claimReward(uint8 rewardType, address holder) external;
    function claimReward(uint8 rewardType, address holder, address[] calldata) external;
    function claimReward(uint8 rewardType, address[] calldata holders, address[] calldata qiTokens, bool borrowers, bool suppliers) external;
}

interface QiInterface {
    function delegate(address delegatee) external;
    function delegates(address) external view returns(address);
}

interface BenqiMappingInterface {
    function qiTokenMapping(string calldata tokenId) external view returns (address);
    function getMapping(string calldata tokenId) external view returns (address, address);
}