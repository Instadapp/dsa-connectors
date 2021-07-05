pragma solidity ^0.7.0;

/**
 * @title NexusMutual.
 * @dev Manage NexusMutual to DSA.
 */

import {AccountInterface} from "../../common/interfaces.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

abstract contract NexusMutualResolver is Events, Helpers {
    /**
     * @dev buy cover for a coverable identified by its contractAddress
     * @notice buy cover for a coverable identified by its contractAddress
     * @param contractAddress contract address of coverable
     * @param coverAsset asset of the premium and of the sum assured.
     * @param sumAssured amount payable if claim is submitted and considered valid
     * @param coverPeriod coverPeriod
     * @param coverType cover type determining how the data parameter is decoded
     * @param data abi-encoded field with additional cover data fields
     */
    function buyCover(
        address contractAddress,
        address coverAsset,
        uint256 sumAssured,
        uint16 coverPeriod,
        CoverType coverType,
        bytes calldata data
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 coverId;
        if (coverAsset == ethAddr) {
            coverId = gateway.buyCover{value: address(this).balance}(
                contractAddress,
                coverAsset,
                sumAssured,
                coverPeriod,
                coverType,
                data
            );
        } else {
            TokenInterface tokenContract = TokenInterface(coverAsset);

            approve(
                tokenContract,
                gateway,
                tokenContract.balanceOf(address(this))
            );
            coverId = gateway.buyCover(
                contractAddress,
                coverAsset,
                sumAssured,
                coverPeriod,
                coverType,
                data
            );
        }

        _eventName = "LogBuyCover(address,address,uint256,uint16,uint256)";
        _eventParam = abi.encode(
            contractAddress,
            coverAsset,
            sumAssured,
            coverPeriod,
            coverId
        );
    }

    /**
     * @dev Submits a claim for a given cover note.
     * @notice Adds claim to queue incase of emergency pause else directly submits the claim.
     * @param coverId Cover Id.
     * @param data abi-encoded field with additional cover data fields
     */
    function submitClaim(uint256 coverId, bytes calldata data)
        external
        returns (string memory _eventName, bytes memory _eventParam)
    {
        gateway.submitClaim(coverId, data);

        _eventName = "LogSubmitClaim(uint256)";
        _eventParam = abi.encode(coverId);
    }

    /**
     * @dev Submit a claim for the cover
     * @notice Submit a claim for the cover
     * @param coverId cover token id
     * @param incidentId id of the incident
     * @param coveredTokenAmount amount of yield tokens covered
     * @param coverAsset yield token that is covered
     */
    function claimTokens(
        uint256 coverId,
        uint256 incidentId,
        uint256 coveredTokenAmount,
        address coverAsset
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        (, uint256 payoutAmount, address payoutToken) = gateway.claimTokens(
            coverId,
            incidentId,
            coveredTokenAmount,
            coverAsset
        );

        _eventName = "LogClaimTokens(uint256,uint256,uint256,address)";
        _eventParam = abi.encode(
            coverId,
            incidentId,
            payoutAmount,
            payoutToken
        );
    }

    /**
    * @notice Execute an action on a specific cover token. The action is identified by an `action` id.
        Allows for an ETH transfer or an ERC20 transfer.
        If less than the supplied assetAmount is needed, it is returned to `msg.sender`.
    * @dev The purpose of this function is future-proofing for updates to the cover buy->claim cycle.
    * @param tokenId id of the cover token
    * @param action action identifier
    * @param data abi-encoded field with action parameters
    */
    function executeCoverAction(
        uint256 tokenId,
        uint8 action,
        bytes calldata data
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        gateway.executeCoverAction(tokenId, action, data);

        _eventName = "LogExecuteCoverAction(uint256,uint8)";
        _eventParam = abi.encode(tokenId, action);
    }
}

contract ConnectV2NexusMutual is NexusMutualResolver {
    string public constant name = "NexusMutualv1";
}
