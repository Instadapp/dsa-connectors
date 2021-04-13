pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract IncentivesResolver is Helpers, Events {

    function claim(
        address[] calldata assets,
        uint256 amt,
        bool stake,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(assets.length > 0, "invalid-assets");

        _amt = incentives.claimRewards(assets, _amt, address(this), stake);

        setUint(setId, _amt);

        _eventName = "LogClaimed(address[],uint256,bool,uint256,uint256)";
        _eventParam = abi.encode(assets, _amt, stake, getId, setId);
    }
}

contract ConnectV2AaveIncentives is IncentivesResolver {
    string public constant name = "Aave-Incentives-v1";
}