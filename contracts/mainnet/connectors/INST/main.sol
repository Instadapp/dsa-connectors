pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Instadapp Governance.
 * @dev Governance.
 */
import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract Resolver is Events, Helpers {

    /**
     * @dev Delegate votes.
     * @notice Delegating votes to delegatee.
     * @param delegatee The address to delegate the votes.
    */
    function delegate(address delegatee) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(instToken.delegates(address(this)) != delegatee, "Already delegated to same delegatee.");

        instToken.delegate(delegatee);

        _eventName = "LogDelegate(address)";
        _eventParam = abi.encode(delegatee);
    }


    /**
     * @dev Cast vote.
      * @notice Casting vote for a proposal
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
    */
    function voteCast(uint256 proposalId, uint256 support) external payable returns (string memory _eventName, bytes memory _eventParam) {
        instaGovernor.castVoteWithReason(proposalId, uint8(support), "");

        _eventName = "LogVoteCast(uint256,uint256,string)";
        _eventParam = abi.encode(proposalId, support, "");
    }

    /**
     * @dev Cast vote with reason.
      * @notice Casting vote for a proposal
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
      * @param reason The reason given for the vote
    */
    function voteCastWithReason(uint256 proposalId, uint256 support, string calldata reason) external payable returns (string memory _eventName, bytes memory _eventParam) {
        instaGovernor.castVoteWithReason(proposalId, uint8(support), reason);

        _eventName = "LogVoteCast(uint256,uint256,string)";
        _eventParam = abi.encode(proposalId, support, reason);
    }
}

contract ConnectV2InstadappGovernanceBravo is Resolver {
    string public constant name = "Instadapp-governance-bravo-v1";
}
