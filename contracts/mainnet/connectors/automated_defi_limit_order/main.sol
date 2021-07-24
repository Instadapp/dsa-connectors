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

    function create(
        address _tokenFrom,
        address _tokenTo,
        uint128 _price,
        uint32 _route,
        bytes8 _pos
    ) external payable returns (
        string memory _eventName,
        bytes memory _eventParam
    ) {
        if (_pos == bytes8(0)) {
            limitOrderContract.create(_tokenFrom, _tokenTo, _price, _route);
        } else {
            limitOrderContract.create(_tokenFrom, _tokenTo, _price, _route, _pos);
        }

        _eventName = "LogCreate(address,address,uint256,uint32,bytes8)";
        _eventParam = abi.encode(_tokenFrom, _tokenTo, _price, _route, _pos);
    }

    function cancel(
        address _tokenFrom,
        address _tokenTo,
        bytes8 _orderId
    ) external payable returns (
        string memory _eventName,
        bytes memory _eventParam
    ) {
        limitOrderContract.cancel(_tokenFrom, _tokenTo, _orderId);

        _eventName = "LogCancel(address,address,bytes8)";
        _eventParam = abi.encode(_tokenFrom, _tokenTo, _orderId);
    }

    function cancelPublic(
        address _tokenFrom,
        address _tokenTo,
        bytes8 _orderId
    ) external payable returns (
        string memory _eventName,
        bytes memory _eventParam
    ) {
        limitOrderContract.cancelPublic(_tokenFrom, _tokenTo, _orderId);

        _eventName = "LogCancelPublic(address,address,bytes8)";
        _eventParam = abi.encode(_tokenFrom, _tokenTo, _orderId);
    }

    function _calSlippageCheck(
        TokenInterface buyToken,
        TokenInterface sellToken,
        uint sellAmt,
        uint unitAmt
    ) internal view returns (uint _slippageAmt) {
        TokenInterface buyToken = TokenInterface(buyAddr);
        TokenInterface sellToken = TokenInterface(sellAddr);
        (uint _buyDec, uint _sellDec) = getTokensDec(buyToken, sellToken);
        uint _sellAmt18 = convertTo18(_sellDec, sellAmt);
        _slippageAmt = convert18ToDec(_buyDec, wmul(unitAmt, _sellAmt18));
    }

    function sell(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        bytes8 _orderId,
        uint getId,
        uint setId
    ) external payable returns (
        string memory _eventName,
        bytes memory _eventParam
    ) {
        uint _slippageAmt = _calSlippageCheck(TokenInterface(buyAddr), TokenInterface(sellAddr), sellAmt, unitAmt);

        uint buyAmt = limitOrderContract.sell(sellAddr, buyAddr, sellAmt, _slippageAmt, _orderId, address(this));

        _eventName = "LogSell(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(buyAddr, sellAddr, buyAmt, sellAmt, 0, setId);
    }

    function sell(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        bytes8[] memory orderIds,
        uint[] memory distributions,
        uint units,
        uint getId,
        uint setId
    ) external payable returns (
        string memory _eventName,
        bytes memory _eventParam
    ) {
        uint _slippageAmt = _calSlippageCheck(TokenInterface(buyAddr), TokenInterface(sellAddr), sellAmt, unitAmt);

        uint buyAmt = limitOrderContract.sell(sellAddr, buyAddr, sellAmt, _slippageAmt, orderIds, distributions, units, address(this));

        _eventName = "LogSell(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(buyAddr, sellAddr, buyAmt, sellAmt, 0, setId);
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

contract ConnectV2DefiLimitOrders is CompResolver {
    string public constant name = "DeFi-Limit-Order-v1";
}
