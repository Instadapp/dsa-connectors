pragma solidity ^0.7.0;

contract Events {
    event LogBuyCover(
        address indexed _contractAddress,
        address indexed _coverAsset,
        uint256 sumAssured,
        uint16 coverPeriod,
        uint256 coverId
    );

    event LogSubmitClaim(uint256 indexed coverId);

    event LogClaimTokens(
        uint256 indexed coverId,
        uint256 indexed incidentId,
        uint256 payoutAmount,
        address payoutToken
    );

    event LogExecuteCoverAction(uint256 indexed tokenId, uint8 action);
}
