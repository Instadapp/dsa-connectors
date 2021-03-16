pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IndexInterface {
    function master() external view returns (address);
}

interface ConnectorsInterface {
    function chief(address) external view returns (bool);
}

interface CTokenInterface {
    function isCToken() external view returns (bool);
}

abstract contract Helpers {

    event LogCTokensAdded(string[] names, address[] ctokens);
    event LogCTokensUpdated(string[] names, address[] ctokens);

    ConnectorsInterface public immutable connectors;

    // InstaIndex Address.
    IndexInterface public constant instaIndex = IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);

    mapping (string => address) public cTokenMapping;

    modifier isChief {
        require(msg.sender == instaIndex.master() || connectors.chief(msg.sender), "not-an-chief");
        _;
    }

    constructor(address _connectors) {
        connectors = ConnectorsInterface(_connectors);
    }

    function _addCtokenMapping(string[] memory _names, address[] memory _ctokens) internal {
        require(_names.length == _ctokens.length, "addCtokenMapping: not same length");
        for (uint i = 0; i < _ctokens.length; i++) {
            require(cTokenMapping[_names[i]] == address(0), "addCtokenMapping: mapping added already");
            require(_ctokens[i] != address(0), "addCtokenMapping: _ctokens address not vaild");
            require(CTokenInterface(_ctokens[i]).isCToken(), "addCtokenMapping: not a cToken");

            cTokenMapping[_names[i]] = _ctokens[i];
            // emit LogCTokenAdded(_names[i], _ctokens[i]);
        }
        emit LogCTokensAdded(_names, _ctokens);
    }

    function updateCtokenMapping(string[] calldata _names, address[] calldata _ctokens) external {
        require(msg.sender == instaIndex.master(), "not-master");
        require(_names.length == _ctokens.length, "updateCtokenMapping: not same length");
        for (uint i = 0; i < _ctokens.length; i++) {
            require(cTokenMapping[_names[i]] != address(0), "updateCtokenMapping: mapping does not exist");
            require(_ctokens[i] != address(0), "updateCtokenMapping: _ctokens address not vaild");
            require(CTokenInterface(_ctokens[i]).isCToken(), "updateCtokenMapping: not a cToken");

            cTokenMapping[_names[i]] = _ctokens[i];
        }
        emit LogCTokensUpdated(_names, _ctokens);
    }

    function addCtokenMapping(string[] memory _names, address[] memory _ctokens) external isChief {
        _addCtokenMapping(_names, _ctokens);
    }

}

contract InstaMapping is Helpers {
    string constant public name = "Compound-Mapping-v1";

    constructor(
        address _connectors,
        string[] memory _ctokenNames,
        address[] memory _ctokens
    ) Helpers(_connectors) {
        _addCtokenMapping(_ctokenNames, _ctokens);
    }
}