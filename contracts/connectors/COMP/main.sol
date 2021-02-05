pragma solidity ^0.6.0;

import { TokenInterface , MemoryInterface, EventInterface, InstaMapping } from "../../common/interfaces.sol";
import { ComptrollerInterface, COMPInterface } from "./interface.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

contract CompResolver is Events, Helpers {

    /**
     * @dev Claim Accrued COMP Token.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
    */
    function ClaimComp(uint setId) external payable {
        TokenInterface compToken = TokenInterface(getCompTokenAddress());
        uint intialBal = compToken.balanceOf(address(this));
        ComptrollerInterface(getComptrollerAddress()).claimComp(address(this));
        uint finalBal = compToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        emit LogClaimedComp(amt, setId);
        bytes32 _eventCode = keccak256("LogClaimedComp(uint256,uint256)");
        bytes memory _eventParam = abi.encode(amt, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Claim Accrued COMP Token.
     * @param tokens Array of tokens supplied and borrowed.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
    */
    function ClaimCompTwo(address[] calldata tokens, uint setId) external payable {
        uint _len = tokens.length;
        address[] memory ctokens = new address[](_len);
        for (uint i = 0; i < _len; i++) {
            ctokens[i] = InstaMapping(getMappingAddr()).cTokenMapping(tokens[i]);
        }

        TokenInterface compToken = TokenInterface(getCompTokenAddress());
        uint intialBal = compToken.balanceOf(address(this));
        ComptrollerInterface(getComptrollerAddress()).claimComp(address(this), ctokens);
        uint finalBal = compToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        emit LogClaimedComp(amt, setId);
        bytes32 _eventCode = keccak256("LogClaimedComp(uint256,uint256)");
        bytes memory _eventParam = abi.encode(amt, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Claim Accrued COMP Token.
     * @param supplyTokens Array of tokens supplied.
     * @param borrowTokens Array of tokens borrowed.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
    */
    function ClaimCompThree(address[] calldata supplyTokens, address[] calldata borrowTokens, uint setId) external payable {
       (address[] memory ctokens, bool isBorrow, bool isSupply) = mergeTokenArr(supplyTokens, borrowTokens);

        address[] memory holders = new address[](1);
        holders[0] = address(this);

        TokenInterface compToken = TokenInterface(getCompTokenAddress());
        uint intialBal = compToken.balanceOf(address(this));
        ComptrollerInterface(getComptrollerAddress()).claimComp(holders, ctokens, isBorrow, isSupply);
        uint finalBal = compToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        emit LogClaimedComp(amt, setId);
        bytes32 _eventCode = keccak256("LogClaimedComp(uint256,uint256)");
        bytes memory _eventParam = abi.encode(amt, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Delegate votes.
     * @param delegatee The address to delegate votes to.
    */
    function delegate(address delegatee) external payable {
        COMPInterface compToken = COMPInterface(getCompTokenAddress());
        require(compToken.delegates(address(this)) != delegatee, "Already delegated to same delegatee.");

        compToken.delegate(delegatee);

        emit LogDelegate(delegatee);
        bytes32 _eventCode = keccak256("LogDelegate(address)");
        bytes memory _eventParam = abi.encode(delegatee);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }
}

contract ConnectCOMP is CompResolver {
    string public name = "COMP-v1";
}
