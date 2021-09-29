pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IndexInterface {
    function master() external view returns (address);
}

interface ConnectorsInterface {
    function chief(address) external view returns (bool);
}

interface QiTokenInterface {
    function isQiToken() external view returns (bool);
    function underlying() external view returns (address);
}

abstract contract Helpers {

    struct TokenMap {
        address qitoken;
        address token;
    }

    event LogQiTokenAdded(string indexed name, address indexed token, address indexed qitoken);
    event LogQiTokenUpdated(string indexed name, address indexed token, address indexed qitoken);

    ConnectorsInterface public immutable connectors;

    // InstaIndex Address.
    IndexInterface public constant instaIndex = IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);

    address public constant avaxAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping (string => TokenMap) public qiTokenMapping;

    modifier isChief {
        require(msg.sender == instaIndex.master() || connectors.chief(msg.sender), "not-an-chief");
        _;
    }

    constructor(address _connectors) {
        connectors = ConnectorsInterface(_connectors);
    }

    function _addQitokenMapping(
        string[] memory _names,
        address[] memory _tokens,
        address[] memory _qitokens
    ) internal {
        require(_names.length == _tokens.length, "addQitokenMapping: not same length");
        require(_names.length == _qitokens.length, "addQitokenMapping: not same length");

        for (uint i = 0; i < _qitokens.length; i++) {
            TokenMap memory _data = qiTokenMapping[_names[i]];

            require(_data.qitoken == address(0), "addQitokenMapping: mapping added already");
            require(_data.token == address(0), "addQitokenMapping: mapping added already");

            require(_tokens[i] != address(0), "addQitokenMapping: _tokens address not vaild");
            require(_qitokens[i] != address(0), "addQitokenMapping: _qitokens address not vaild");

            QiTokenInterface _qitokenContract = QiTokenInterface(_qitokens[i]);

            require(_qitokenContract.isQiToken(), "addQitokenMapping: not a qiToken");
            if (_tokens[i] != avaxAddr) {
                require(_qitokenContract.underlying() == _tokens[i], "addQitokenMapping: mapping mismatch");
            }

            qiTokenMapping[_names[i]] = TokenMap(
                _qitokens[i],
                _tokens[i]
            );
            emit LogQiTokenAdded(_names[i], _tokens[i], _qitokens[i]);
        }
    }

    function updateQitokenMapping(
        string[] calldata _names,
        address[] memory _tokens,
        address[] calldata _qitokens
    ) external {
        require(msg.sender == instaIndex.master(), "not-master");

        require(_names.length == _tokens.length, "updateQitokenMapping: not same length");
        require(_names.length == _qitokens.length, "updateQitokenMapping: not same length");

        for (uint i = 0; i < _qitokens.length; i++) {
            TokenMap memory _data = qiTokenMapping[_names[i]];

            require(_data.qitoken != address(0), "updateQitokenMapping: mapping does not exist");
            require(_data.token != address(0), "updateQitokenMapping: mapping does not exist");

            require(_tokens[i] != address(0), "updateQitokenMapping: _tokens address not vaild");
            require(_qitokens[i] != address(0), "updateQitokenMapping: _qitokens address not vaild");

            QiTokenInterface _qitokenContract = QiTokenInterface(_qitokens[i]);

            require(_qitokenContract.isQiToken(), "updateQitokenMapping: not a qiToken");
            if (_tokens[i] != avaxAddr) {
                require(_qitokenContract.underlying() == _tokens[i], "addQitokenMapping: mapping mismatch");
            }

            qiTokenMapping[_names[i]] = TokenMap(
                _qitokens[i],
                _tokens[i]
            );
            emit LogQiTokenUpdated(_names[i], _tokens[i], _qitokens[i]);
        }
    }

    function addQitokenMapping(
        string[] memory _names,
        address[] memory _tokens,
        address[] memory _qitokens
    ) external isChief {
        _addQitokenMapping(_names, _tokens, _qitokens);
    }

    function getMapping(string memory _tokenId) external view returns (address, address) {
        TokenMap memory _data = qiTokenMapping[_tokenId];
        return (_data.token, _data.qitoken);
    }

}

contract InstaBenqiMapping is Helpers {
    string constant public name = "Benqi-Mapping-v1.0";

    constructor(
        address _connectors,
        string[] memory _qitokenNames,
        address[] memory _tokens,
        address[] memory _qitokens
    ) Helpers(_connectors) {
        _addQitokenMapping(_qitokenNames, _tokens, _qitokens);
    }
}