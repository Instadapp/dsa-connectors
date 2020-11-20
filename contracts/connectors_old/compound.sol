pragma solidity ^0.6.0;

interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint); // For ERC20
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function exchangeRateCurrent() external returns (uint);

    function balanceOf(address owner) external view returns (uint256 balance);
}

interface CETHInterface {
    function mint() external payable;
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
}

interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cTokenAddress) external returns (uint);
    function getAssetsIn(address account) external view returns (address[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
    function claimComp(address) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
}

interface MemoryInterface {
    function getUint(uint _id) external returns (uint _num);
    function setUint(uint _id, uint _val) external;
}

interface EventInterface {
    function emitEvent(uint _connectorType, uint _connectorID, bytes32 _eventCode, bytes calldata _eventData) external;
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

}


contract Helpers is DSMath {
    /**
     * @dev Return ethereum address
     */
    function getAddressETH() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev Return Memory Variable Address
     */
    function getMemoryAddr() internal pure returns (address) {
        return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F; // InstaMemory Address
    }

    /**
     * @dev Return InstaEvent Address.
     */
    function getEventAddr() internal pure returns (address) {
        return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97; // InstaEvent Address
    }

    /**
     * @dev Get Uint value from InstaMemory Contract.
    */
    function getUint(uint getId, uint val) internal returns (uint returnVal) {
        returnVal = getId == 0 ? val : MemoryInterface(getMemoryAddr()).getUint(getId);
    }

    /**
     * @dev Set Uint value in InstaMemory Contract.
    */
    function setUint(uint setId, uint val) internal {
        if (setId != 0) MemoryInterface(getMemoryAddr()).setUint(setId, val);
    }

    /**
     * @dev Connector Details
    */
    function connectorID() public pure returns(uint _type, uint _id) {
        (_type, _id) = (1, 24);
    }
}


contract CompoundHelpers is Helpers {
    /**
     * @dev Return Compound Comptroller Address
     */
    function getComptrollerAddress() internal pure returns (address) {
        return 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    }

    /**
     * @dev Return COMP Token Address.
     */
    function getCompTokenAddress() internal pure returns (address) {
        return 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    }

    /**
     * @dev Return InstaDApp Mapping Addresses
     */
    function getMappingAddr() internal pure returns (address) {
        return 0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88; // InstaMapping Address
    }

    /**
     * @dev enter compound market
     */
    function enterMarket(address cToken) internal {
        ComptrollerInterface troller = ComptrollerInterface(getComptrollerAddress());
        address[] memory markets = troller.getAssetsIn(address(this));
        bool isEntered = false;
        for (uint i = 0; i < markets.length; i++) {
            if (markets[i] == cToken) {
                isEntered = true;
            }
        }
        if (!isEntered) {
            address[] memory toEnter = new address[](1);
            toEnter[0] = cToken;
            troller.enterMarkets(toEnter);
        }
    }
}


contract BasicResolver is CompoundHelpers {
    event LogDeposit(address indexed token, address cToken, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdraw(address indexed token, address cToken, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogBorrow(address indexed token, address cToken, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogPayback(address indexed token, address cToken, uint256 tokenAmt, uint256 getId, uint256 setId);

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @param token token address to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to deposit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(address token, uint amt, uint getId, uint setId) external payable{
        uint _amt = getUint(getId, amt);
        address cToken = InstaMapping(getMappingAddr()).cTokenMapping(token);
        enterMarket(cToken);
        if (token == getAddressETH()) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            CETHInterface(cToken).mint.value(_amt)();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(cToken, _amt);
            require(CTokenInterface(cToken).mint(_amt) == 0, "borrow-failed");
        }
        setUint(setId, _amt);

        emit LogDeposit(token, cToken, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogDeposit(address,address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, cToken, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @param token token address to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdraw(address token, uint amt, uint getId, uint setId) external payable{
        uint _amt = getUint(getId, amt);
        address cToken = InstaMapping(getMappingAddr()).cTokenMapping(token);
        CTokenInterface cTokenContract = CTokenInterface(cToken);
        if (_amt == uint(-1)) {
            TokenInterface tokenContract = TokenInterface(token);
            uint initialBal = token == getAddressETH() ? address(this).balance : tokenContract.balanceOf(address(this));
            require(cTokenContract.redeem(cTokenContract.balanceOf(address(this))) == 0, "full-withdraw-failed");
            uint finalBal = token == getAddressETH() ? address(this).balance : tokenContract.balanceOf(address(this));
            _amt = finalBal - initialBal;
        } else {
            require(cTokenContract.redeemUnderlying(_amt) == 0, "withdraw-failed");
        }
        setUint(setId, _amt);

        emit LogWithdraw(token, cToken, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogWithdraw(address,address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, cToken, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @param token token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to borrow.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function borrow(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);
        address cToken = InstaMapping(getMappingAddr()).cTokenMapping(token);
        enterMarket(cToken);
        require(CTokenInterface(cToken).borrow(_amt) == 0, "borrow-failed");
        setUint(setId, _amt);

        emit LogBorrow(token, cToken, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogBorrow(address,address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, cToken, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @param token token address to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to payback.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function payback(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);
        address cToken = InstaMapping(getMappingAddr()).cTokenMapping(token);
        CTokenInterface cTokenContract = CTokenInterface(cToken);
        _amt = _amt == uint(-1) ? cTokenContract.borrowBalanceCurrent(address(this)) : _amt;

        if (token == getAddressETH()) {
            require(address(this).balance >= _amt, "not-enough-eth");
            CETHInterface(cToken).repayBorrow.value(_amt)();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            tokenContract.approve(cToken, _amt);
            require(cTokenContract.repayBorrow(_amt) == 0, "repay-failed.");
        }
        setUint(setId, _amt);

        emit LogPayback(token, cToken, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogPayback(address,address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, cToken, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }
}

contract ExtraResolver is BasicResolver {
    event LogClaimedComp(uint256 compAmt, uint256 setId);
    event LogDepositCToken(address indexed token, address cToken, uint256 tokenAmt, uint256 cTokenAmt,uint256 getId, uint256 setId);
    event LogWithdrawCToken(address indexed token, address cToken, uint256 cTokenAmt, uint256 getId, uint256 setId);
    event LogLiquidate(
        address indexed borrower,
        address indexed tokenToPay,
        address indexed tokenInReturn,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

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
     * @dev Deposit ETH/ERC20_Token.
     * @param token token address to depositCToken.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to depositCToken.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
    */
    function depositCToken(address token, uint amt, uint getId, uint setId) external payable{
        uint _amt = getUint(getId, amt);
        address cToken = InstaMapping(getMappingAddr()).cTokenMapping(token);
        enterMarket(cToken);

        CTokenInterface ctokenContract = CTokenInterface(cToken);
        uint initialBal = ctokenContract.balanceOf(address(this));

        if (token == getAddressETH()) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            CETHInterface(cToken).mint.value(_amt)();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(cToken, _amt);
            require(ctokenContract.mint(_amt) == 0, "deposit-ctoken-failed.");
        }

        uint finalBal = ctokenContract.balanceOf(address(this));
        uint _cAmt = finalBal - initialBal;
        setUint(setId, _cAmt);

        emit LogDepositCToken(token, cToken, _amt, _cAmt, getId, setId);
        bytes32 _eventCode = keccak256("LogDepositCToken(address,address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, cToken, _amt, _cAmt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Withdraw CETH/CERC20_Token using cToken Amt.
     * @param token token address to withdraw CToken.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param cTokenAmt ctoken amount to withdrawCToken.
     * @param getId Get ctoken amount at this ID from `InstaMemory` Contract.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
    */
    function withdrawCToken(address token, uint cTokenAmt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, cTokenAmt);
        address cToken = InstaMapping(getMappingAddr()).cTokenMapping(token);
        CTokenInterface cTokenContract = CTokenInterface(cToken);
        _amt = _amt == uint(-1) ? cTokenContract.balanceOf(address(this)) : _amt;
        require(cTokenContract.redeem(_amt) == 0, "redeem-failed");
        setUint(setId, _amt);

        emit LogWithdrawCToken(token, cToken, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogWithdrawCToken(address,address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, cToken, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);

    }

    /**
     * @dev Liquidate a position.
     * @param borrower Borrower's Address.
     * @param tokenToPay token address to pay for liquidation.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param tokenInReturn token address to return for liquidation.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to pay for liquidation.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function liquidate(
        address borrower,
        address tokenToPay,
        address tokenInReturn,
        uint amt,
        uint getId,
        uint setId
    ) external payable
    {
        uint _amt = getUint(getId, amt);
        address cTokenPay = InstaMapping(getMappingAddr()).cTokenMapping(tokenToPay);
        address cTokenColl = InstaMapping(getMappingAddr()).cTokenMapping(tokenInReturn);
        CTokenInterface cTokenContract = CTokenInterface(cTokenPay);

        (,, uint shortfal) = ComptrollerInterface(getComptrollerAddress()).getAccountLiquidity(borrower);
        require(shortfal != 0, "account-cannot-be-liquidated");

        _amt = _amt == uint(-1) ? cTokenContract.borrowBalanceCurrent(borrower) : _amt;
        if (tokenToPay == getAddressETH()) {
            require(address(this).balance >= _amt, "not-enought-eth");
            CETHInterface(cTokenPay).liquidateBorrow.value(_amt)(borrower, cTokenColl);
        } else {
            TokenInterface tokenContract = TokenInterface(tokenToPay);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            tokenContract.approve(cTokenPay, _amt);
            require(cTokenContract.liquidateBorrow(borrower, _amt, cTokenColl) == 0, "liquidate-failed");
        }
        setUint(setId, _amt);

        emit LogLiquidate(
            address(this),
            tokenToPay,
            tokenInReturn,
            _amt,
            getId,
            setId
        );
        bytes32 _eventCode = keccak256("LogLiquidate(address,address,address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(
            address(this),
            tokenToPay,
            tokenInReturn,
            _amt,
            getId,
            setId
        );
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);

    }
}


contract ConnectCompound is ExtraResolver {
    string public name = "Compound-v1.2";
}