pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IGateway {
    enum CoverType {
        SIGNED_QUOTE_CONTRACT_COVER
    }

    function buyCover(
        address contractAddress,
        address coverAsset,
        uint256 sumAssured,
        uint16 coverPeriod,
        CoverType coverType,
        bytes calldata data
    ) external payable returns (uint256);

    function submitClaim(uint256 coverId, bytes calldata data)
        external
        returns (uint256);

    function claimTokens(
        uint256 coverId,
        uint256 incidentId,
        uint256 coveredTokenAmount,
        address coverAsset
    )
        external
        returns (
            uint256 claimId,
            uint256 payoutAmount,
            address payoutToken
        );

    function executeCoverAction(
        uint256 tokenId,
        uint8 action,
        bytes calldata data
    ) external payable returns (bytes memory, uint256);
}
