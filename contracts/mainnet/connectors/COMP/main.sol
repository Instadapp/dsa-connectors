pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title COMP.
 * @dev Claim COMP.
 */
import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract CompResolver is Events, Helpers {

    /**
     * @dev Claim Accrued COMP Token.
     * @notice Claim Accrued COMP Token.
     * @param setId ID stores the amount of COMP claimed.
    */
    function ClaimComp(uint256 setId) external payable returns (string memory _eventName, bytes memory _eventParam) {
        TokenInterface _compToken = TokenInterface(address(compToken));
        uint intialBal = _compToken.balanceOf(address(this));
        troller.claimComp(address(this));
        uint finalBal = _compToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        _eventName = "LogClaimedComp(uint256,uint256)";
        _eventParam = abi.encode(amt, setId);
    }

    /**
     * @dev Claim Accrued COMP Token.
     * @notice Claim Accrued COMP Token.
     * @param tokenIds Array of supplied and borrowed token IDs.
     * @param setId ID stores the amount of COMP claimed.
    */
    function ClaimCompTwo(string[] calldata tokenIds, uint256 setId) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _len = tokenIds.length;
        address[] memory ctokens = new address[](_len);
        for (uint i = 0; i < _len; i++) {
            (address token, address cToken) = compMapping.getMapping(tokenIds[i]);
            require(token != address(0) && cToken != address(0), "invalid token/ctoken address");

            ctokens[i] = cToken;
        }

        TokenInterface _compToken = TokenInterface(address(compToken));
        uint intialBal = _compToken.balanceOf(address(this));
        troller.claimComp(address(this), ctokens);
        uint finalBal = _compToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        _eventName = "LogClaimedComp(uint256,uint256)";
        _eventParam = abi.encode(amt, setId);
    }

    /**
     * @dev Claim Accrued COMP Token.
     * @notice Claim Accrued COMP Token.
     * @param supplyTokenIds Array of supplied tokenIds.
     * @param borrowTokenIds Array of borrowed tokenIds.
     * @param setId ID stores the amount of COMP claimed.
    */
    function ClaimCompThree(string[] calldata supplyTokenIds, string[] calldata borrowTokenIds, uint256 setId) external payable returns (string memory _eventName, bytes memory _eventParam) {
       (address[] memory ctokens, bool isBorrow, bool isSupply) = getMergedCTokens(supplyTokenIds, borrowTokenIds);

        address[] memory holders = new address[](1);
        holders[0] = address(this);

        TokenInterface _compToken = TokenInterface(address(compToken));
        uint intialBal = _compToken.balanceOf(address(this));
        troller.claimComp(holders, ctokens, isBorrow, isSupply);
        uint finalBal = _compToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        _eventName = "LogClaimedComp(uint256,uint256)";
        _eventParam = abi.encode(amt, setId);
    }

    /**
     * @dev Delegate votes.
     * @notice Delegate votes.
     * @param delegatee The address to delegate the votes to.
    */
    function delegate(address delegatee) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(compToken.delegates(address(this)) != delegatee, "Already delegated to same delegatee.");

        compToken.delegate(delegatee);

        _eventName = "LogDelegate(address)";
        _eventParam = abi.encode(delegatee);
    }
}

contract ConnectV2COMP is CompResolver {
    string public constant name = "COMP-v1.1";
}
