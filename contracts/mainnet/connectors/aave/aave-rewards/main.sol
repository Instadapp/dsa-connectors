pragma solidity ^0.7.0;

/**
 * @title Aave Rewards.
 * @dev Claim Aave rewards.
 */

import { TokenInterface } from "../../../common/interfaces.sol";
import { Stores } from "../../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract IncentivesResolver is Helpers, Events {

    /**
     * @dev Claim Pending Rewards.
     * @notice Claim Pending Rewards from Aave incentives contract.
     * @param assets The list of assets supplied and borrowed.
     * @param amt The amount of reward to claim. (uint(-1) for max)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of rewards claimed.
    */
    function claim(
        address[] calldata assets,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(assets.length > 0, "invalid-assets");

        _amt = incentives.claimRewards(assets, _amt, address(this));

        setUint(setId, _amt);

        _eventName = "LogClaimed(address[],uint256,uint256,uint256)";
        _eventParam = abi.encode(assets, _amt, getId, setId);
    }
}

contract ConnectV2AaveIncentives is IncentivesResolver {
    string public constant name = "Aave-Incentives-v1";
}
