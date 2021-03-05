pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface SoloMarginContract {

    struct Info {
        address owner;
        uint256 number;
    }

    enum ActionType {
        Deposit,
        Withdraw,
        Transfer,
        Buy,
        Sell,
        Trade,
        Liquidate,
        Vaporize,
        Call
    }

    enum AssetDenomination {
        Wei,
        Par
    }

    enum AssetReference {
        Delta,
        Target
    }

    struct AssetAmount {
        bool sign;
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Wei {
        bool sign;
        uint256 value;
    }

    function operate(Info[] calldata accounts, ActionArgs[] calldata actions) external;
    function getAccountWei(Info calldata account, uint256 marketId) external returns (Wei memory);
    function getNumMarkets() external view returns (uint256);
    function getMarketTokenAddress(uint256 marketId) external view returns (address);

}
