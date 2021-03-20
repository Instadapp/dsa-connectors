pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract CompResolver is Events, Helpers {

    /**
     * @dev Claim Accrued COMP Token.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
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
     * @param tokens Array of tokens supplied and borrowed.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
    */
    function ClaimCompTwo(address[] calldata tokens, uint256 setId) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _len = tokens.length;
        address[] memory ctokens = new address[](_len);
        for (uint i = 0; i < _len; i++) {
            ctokens[i] = instaMapping.cTokenMapping(tokens[i]);
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
     * @param supplyTokens Array of tokens supplied.
     * @param borrowTokens Array of tokens borrowed.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
    */
    function ClaimCompThree(address[] calldata supplyTokens, address[] calldata borrowTokens, uint256 setId) external payable returns (string memory _eventName, bytes memory _eventParam) {
       (address[] memory ctokens, bool isBorrow, bool isSupply) = mergeTokenArr(supplyTokens, borrowTokens);

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
     * @param delegatee The address to delegate votes to.
    */
    function delegate(address delegatee) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(compToken.delegates(address(this)) != delegatee, "Already delegated to same delegatee.");

        compToken.delegate(delegatee);

        _eventName = "LogDelegate(address)";
        _eventParam = abi.encode(delegatee);
    }
}

contract ConnectV2COMP is CompResolver {
    string public constant name = "COMP-v1";
}
