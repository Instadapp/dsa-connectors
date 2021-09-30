pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Reward.
 * @dev Claim Reward.
 */
import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract BenqiResolver is Events, Helpers {

    /**
     * @dev Claim Accrued Qi Token.
     * @notice Claim Accrued Qi Token.
     * @param setId ID stores the amount of Reward claimed.
    */
    function ClaimReward(uint256 setId) external payable returns (string memory _eventName, bytes memory _eventParam) {
        TokenInterface _benqiToken = TokenInterface(address(benqiToken));
        uint intialBal = _benqiToken.balanceOf(address(this));
        troller.claimReward(rewardQi, address(this));
        uint finalBal = _benqiToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        _eventName = "LogClaimedReward(uint256,uint256)";
        _eventParam = abi.encode(amt, setId);
    }

    /**
     * @dev Claim Accrued Qi Token.
     * @notice Claim Accrued Qi Token.
     * @param tokenIds Array of supplied and borrowed token IDs.
     * @param setId ID stores the amount of Reward claimed.
    */
    function ClaimRewardTwo(string[] calldata tokenIds, uint256 setId) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _len = tokenIds.length;
        address[] memory qitokens = new address[](_len);
        for (uint i = 0; i < _len; i++) {
            (address token, address qiToken) = qiMapping.getMapping(tokenIds[i]);
            require(token != address(0) && qiToken != address(0), "invalid token/qitoken address");

            qitokens[i] = qiToken;
        }

        TokenInterface _benqiToken = TokenInterface(address(benqiToken));
        uint intialBal = _benqiToken.balanceOf(address(this));
        troller.claimReward(rewardQi, address(this), qitokens);
        uint finalBal = _benqiToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        _eventName = "LogClaimedReward(uint256,uint256)";
        _eventParam = abi.encode(amt, setId);
    }

    /**
     * @dev Claim Accrued Qi Token.
     * @notice Claim Accrued Qi Token.
     * @param supplyTokenIds Array of supplied tokenIds.
     * @param borrowTokenIds Array of borrowed tokenIds.
     * @param setId ID stores the amount of Reward claimed.
    */
    function ClaimRewardThree(string[] calldata supplyTokenIds, string[] calldata borrowTokenIds, uint256 setId) external payable returns (string memory _eventName, bytes memory _eventParam) {
       (address[] memory qitokens, bool isBorrow, bool isSupply) = getMergedQiTokens(supplyTokenIds, borrowTokenIds);

        address[] memory holders = new address[](1);
        holders[0] = address(this);

        TokenInterface _benqiToken = TokenInterface(address(benqiToken));
        uint intialBal = _benqiToken.balanceOf(address(this));
        troller.claimReward(rewardQi, holders, qitokens, isBorrow, isSupply);
        uint finalBal = _benqiToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        _eventName = "LogClaimedReward(uint256,uint256)";
        _eventParam = abi.encode(amt, setId);
    }

    /**
     * @dev Delegate votes.
     * @notice Delegate votes.
     * @param delegatee The address to delegate the votes to.
    */
    function delegate(address delegatee) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(benqiToken.delegates(address(this)) != delegatee, "Already delegated to same delegatee.");

        benqiToken.delegate(delegatee);

        _eventName = "LogDelegate(address)";
        _eventParam = abi.encode(delegatee);
    }
}

contract ConnectV2Benqi is BenqiResolver {
    string public constant name = "Benqi-v1";
}
