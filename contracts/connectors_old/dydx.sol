pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

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


contract DydxHelpers is DSMath, Stores {
    /**
     * @dev get WETH address
    */
    function getWETHAddr() public pure returns (address weth) {
        weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    /**
     * @dev get Dydx Solo Address
    */
    function getDydxAddress() public pure returns (address addr) {
        addr = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    }

    /**
     * @dev Get Dydx Actions args.
    */
    function getActionsArgs(uint256 marketId, uint256 amt, bool sign) internal view returns (SoloMarginContract.ActionArgs[] memory) {
        SoloMarginContract.ActionArgs[] memory actions = new SoloMarginContract.ActionArgs[](1);
        SoloMarginContract.AssetAmount memory amount = SoloMarginContract.AssetAmount(
            sign,
            SoloMarginContract.AssetDenomination.Wei,
            SoloMarginContract.AssetReference.Delta,
            amt
        );
        bytes memory empty;
        SoloMarginContract.ActionType action = sign ? SoloMarginContract.ActionType.Deposit : SoloMarginContract.ActionType.Withdraw;
        actions[0] = SoloMarginContract.ActionArgs(
            action,
            0,
            amount,
            marketId,
            0,
            address(this),
            0,
            empty
        );
        return actions;
    }

    /**
     * @dev Get Dydx Acccount arg
    */
    function getAccountArgs() internal view returns (SoloMarginContract.Info[] memory) {
        SoloMarginContract.Info[] memory accounts = new SoloMarginContract.Info[](1);
        accounts[0] = (SoloMarginContract.Info(address(this), 0));
        return accounts;
    }

    /**
     * @dev Get Dydx Position
    */
    function getDydxPosition(SoloMarginContract solo, uint256 marketId) internal returns (uint tokenBal, bool tokenSign) {
        SoloMarginContract.Wei memory tokenWeiBal = solo.getAccountWei(getAccountArgs()[0], marketId);
        tokenBal = tokenWeiBal.value;
        tokenSign = tokenWeiBal.sign;
    }

    /**
     * @dev Get Dydx Market ID from token Address
    */
    function getMarketId(SoloMarginContract solo, address token) internal view returns (uint _marketId) {
        uint markets = solo.getNumMarkets();
        address _token = token == getEthAddr() ? getWETHAddr() : token;

        for (uint i = 0; i < markets; i++) {
            if (_token == solo.getMarketTokenAddress(i)) {
                _marketId = i;
                break;
            }
        }
    }
}


contract BasicResolver is DydxHelpers {
    event LogDeposit(address indexed token, uint marketId, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdraw(address indexed token, uint marketId, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogBorrow(address indexed token, uint marketId, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogPayback(address indexed token, uint marketId, uint256 tokenAmt, uint256 getId, uint256 setId);

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @param token token address to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to deposit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(address token, uint amt, uint getId, uint setId) external payable{
        SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

        uint _amt = getUint(getId, amt);
        uint _marketId = getMarketId(dydxContract, token);

        (uint depositedAmt, bool sign) = getDydxPosition(dydxContract, _marketId);
        require(depositedAmt == 0 || sign, "token-borrowed");

        if (token == getEthAddr()) {
            TokenInterface tokenContract = TokenInterface(getWETHAddr());
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            tokenContract.deposit.value(_amt)();
            tokenContract.approve(getDydxAddress(), _amt);
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(getDydxAddress(), _amt);
        }

        dydxContract.operate(getAccountArgs(), getActionsArgs(_marketId, _amt, true));
        setUint(setId, _amt);

        emit LogDeposit(token, _marketId, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogDeposit(address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _marketId, _amt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @param token token address to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdraw(address token, uint amt, uint getId, uint setId) external payable{
        SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

        uint _amt = getUint(getId, amt);
        uint _marketId = getMarketId(dydxContract, token);

        (uint depositedAmt, bool sign) = getDydxPosition(dydxContract, _marketId);
        require(sign, "try-payback");

        _amt = _amt == uint(-1) ? depositedAmt : _amt;
        require(_amt <= depositedAmt, "withdraw-exceeds");

        dydxContract.operate(getAccountArgs(), getActionsArgs(_marketId, _amt, false));

        if (token == getEthAddr()) {
            TokenInterface tokenContract = TokenInterface(getWETHAddr());
            tokenContract.approve(address(tokenContract), _amt);
            tokenContract.withdraw(_amt);
        }

        setUint(setId, _amt);

        emit LogWithdraw(token, _marketId, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogWithdraw(address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _marketId, _amt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @param token token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to borrow.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function borrow(address token, uint amt, uint getId, uint setId) external payable {
        SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

        uint _amt = getUint(getId, amt);
        uint _marketId = getMarketId(dydxContract, token);

        (uint borrowedAmt, bool sign) = getDydxPosition(dydxContract, _marketId);
        require(borrowedAmt == 0 || !sign, "token-deposited");

        dydxContract.operate(getAccountArgs(), getActionsArgs(_marketId, _amt, false));

        if (token == getEthAddr()) {
            TokenInterface tokenContract = TokenInterface(getWETHAddr());
            tokenContract.approve(address(tokenContract), _amt);
            tokenContract.withdraw(_amt);
        }

        setUint(setId, _amt);

        emit LogBorrow(token, _marketId, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogBorrow(address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _marketId, _amt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @param token token address to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to payback.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function payback(address token, uint amt, uint getId, uint setId) external payable {
        SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

        uint _amt = getUint(getId, amt);
        uint _marketId = getMarketId(dydxContract, token);

        (uint borrowedAmt, bool sign) = getDydxPosition(dydxContract, _marketId);
        require(!sign, "try-withdraw");

        _amt = _amt == uint(-1) ? borrowedAmt : _amt;
        require(_amt <= borrowedAmt, "payback-exceeds");

        if (token == getEthAddr()) {
            TokenInterface tokenContract = TokenInterface(getWETHAddr());
            require(address(this).balance >= _amt, "not-enough-eth");
            tokenContract.deposit.value(_amt)();
            tokenContract.approve(getDydxAddress(), _amt);
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            tokenContract.approve(getDydxAddress(), _amt);
        }

        dydxContract.operate(getAccountArgs(), getActionsArgs(_marketId, _amt, true));
        setUint(setId, _amt);

        emit LogPayback(token, _marketId, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogPayback(address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _marketId, _amt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }
}


contract ConnectDydx is BasicResolver {
    string public name = "Dydx-v1";
}