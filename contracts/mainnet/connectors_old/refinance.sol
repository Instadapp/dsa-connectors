pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

// Compound Helpers
interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function balanceOf(address owner) external view returns (uint256 balance);
}

interface CETHInterface {
    function mint() external payable;
    function repayBorrow() external payable;
}

interface CompoundMappingInterface {
    function cTokenMapping(string calldata tokenId) external view returns (address);
    function getMapping(string calldata tokenId) external view returns (address, address);
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
}
// End Compound Helpers

// Aave v1 Helpers
interface AaveV1Interface {
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external payable;
    function redeemUnderlying(
        address _reserve,
        address payable _user,
        uint256 _amount,
        uint256 _aTokenBalanceAfterRedeem
    ) external;
    
    function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external;
    function getUserReserveData(address _reserve, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentBorrowBalance,
        uint256 principalBorrowBalance,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint256 liquidityRate,
        uint256 originationFee,
        uint256 variableBorrowIndex,
        uint256 lastUpdateTimestamp,
        bool usageAsCollateralEnabled
    );
    function borrow(address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode) external;
    function repay(address _reserve, uint256 _amount, address payable _onBehalfOf) external payable;
}

interface AaveV1ProviderInterface {
    function getLendingPool() external view returns (address);
    function getLendingPoolCore() external view returns (address);
}

interface AaveV1CoreInterface {
    function getReserveATokenAddress(address _reserve) external view returns (address);
}

interface ATokenV1Interface {
    function redeem(uint256 _amount) external;
    function balanceOf(address _user) external view returns(uint256);
    function principalBalanceOf(address _user) external view returns(uint256);

    function allowance(address, address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}
// End Aave v1 Helpers

// Aave v2 Helpers
interface AaveV2Interface {
    function deposit(address _asset, uint256 _amount, address _onBehalfOf, uint16 _referralCode) external;
    function withdraw(address _asset, uint256 _amount, address _to) external;
    function borrow(
        address _asset,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode,
        address _onBehalfOf
    ) external;
    function repay(address _asset, uint256 _amount, uint256 _rateMode, address _onBehalfOf) external;
    function setUserUseReserveAsCollateral(address _asset, bool _useAsCollateral) external;
}

interface AaveV2LendingPoolProviderInterface {
    function getLendingPool() external view returns (address);
}

// Aave Protocol Data Provider
interface AaveV2DataProviderInterface {
    function getUserReserveData(address _asset, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
}
// End Aave v2 Helpers

contract DSMath {

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
}

contract Helpers is DSMath {

    using SafeERC20 for IERC20;

    enum Protocol {
        Aave,
        AaveV2,
        Compound
    }

    address payable constant feeCollector = 0xb1DC62EC38E6E3857a887210C38418E4A17Da5B2;

    /**
     * @dev Return ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev Return Weth address
    */
    function getWethAddr() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet WETH Address
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // Kovan WETH Address
    }

    /**
     * @dev Return InstaDApp Mapping Address
     */
    function getMappingAddr() internal pure returns (address) {
        return 0xA8F9D4aA7319C54C04404765117ddBf9448E2082; // CompoundMapping Address
    }

    /**
     * @dev Return Compound Comptroller Address
     */
    function getComptrollerAddress() internal pure returns (address) {
        return 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    }

    /**
     * @dev get Aave Provider
    */
    function getAaveProvider() internal pure returns (AaveV1ProviderInterface) {
        return AaveV1ProviderInterface(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8); //mainnet
        // return AaveV1ProviderInterface(0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5); //kovan
    }

    /**
     * @dev get Aave Lending Pool Provider
    */
    function getAaveV2Provider() internal pure returns (AaveV2LendingPoolProviderInterface) {
        return AaveV2LendingPoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5); //mainnet
        // return AaveV2LendingPoolProviderInterface(0x652B2937Efd0B5beA1c8d54293FC1289672AFC6b); //kovan
    }

    /**
     * @dev get Aave Protocol Data Provider
    */
    function getAaveV2DataProvider() internal pure returns (AaveV2DataProviderInterface) {
        return AaveV2DataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d); //mainnet
        // return AaveV2DataProviderInterface(0x744C1aaA95232EeF8A9994C4E0b3a89659D9AB79); //kovan
    }

    /**
     * @dev get Referral Code
    */
    function getReferralCode() internal pure returns (uint16) {
        return 3228;
    }

    function getWithdrawBalance(AaveV1Interface aave, address token) internal view returns (uint bal) {
        (bal, , , , , , , , , ) = aave.getUserReserveData(token, address(this));
    }

    function getPaybackBalance(AaveV1Interface aave, address token) internal view returns (uint bal, uint fee) {
        (, bal, , , , , fee, , , ) = aave.getUserReserveData(token, address(this));
    }

    function getTotalBorrowBalance(AaveV1Interface aave, address token) internal view returns (uint amt) {
        (, uint bal, , , , , uint fee, , , ) = aave.getUserReserveData(token, address(this));
        amt = add(bal, fee);
    }

    function getWithdrawBalanceV2(AaveV2DataProviderInterface aaveData, address token) internal view returns (uint bal) {
        (bal, , , , , , , , ) = aaveData.getUserReserveData(token, address(this));
    }

    function getPaybackBalanceV2(AaveV2DataProviderInterface aaveData, address token, uint rateMode) internal view returns (uint bal) {
        if (rateMode == 1) {
            (, bal, , , , , , , ) = aaveData.getUserReserveData(token, address(this));
        } else {
            (, , bal, , , , , , ) = aaveData.getUserReserveData(token, address(this));
        }
    }

    function getIsColl(AaveV1Interface aave, address token) internal view returns (bool isCol) {
        (, , , , , , , , , isCol) = aave.getUserReserveData(token, address(this));
    }

    function getIsCollV2(AaveV2DataProviderInterface aaveData, address token) internal view returns (bool isCol) {
        (, , , , , , , , isCol) = aaveData.getUserReserveData(token, address(this));
    }

    function convertEthToWeth(bool isEth, TokenInterface token, uint amount) internal {
        if(isEth) token.deposit{value:amount}();
    }

    function convertWethToEth(bool isEth, TokenInterface token, uint amount) internal {
       if(isEth) {
            token.approve(address(token), amount);
            token.withdraw(amount);
        }
    }

    function getMaxBorrow(Protocol target, address token, CTokenInterface ctoken, uint rateMode) internal returns (uint amt) {
        AaveV1Interface aaveV1 = AaveV1Interface(getAaveProvider().getLendingPool());
        AaveV2DataProviderInterface aaveData = getAaveV2DataProvider();

        if (target == Protocol.Aave) {
            (uint _amt, uint _fee) = getPaybackBalance(aaveV1, token);
            amt = _amt + _fee;
        } else if (target == Protocol.AaveV2) {
            amt = getPaybackBalanceV2(aaveData, token, rateMode);
        } else if (target == Protocol.Compound) {
            amt = ctoken.borrowBalanceCurrent(address(this));
        }
    }

    function transferFees(address token, uint feeAmt) internal {
        if (feeAmt > 0) {
            if (token == getEthAddr()) {
                feeCollector.transfer(feeAmt);
            } else {
                IERC20(token).safeTransfer(feeCollector, feeAmt);
            }
        }
    }

    function calculateFee(uint256 amount, uint256 fee, bool toAdd) internal pure returns(uint feeAmount, uint _amount){
        feeAmount = wmul(amount, fee);
        _amount = toAdd ? add(amount, feeAmount) : sub(amount, feeAmount);
    }

    function getTokenInterfaces(uint length, address[] memory tokens) internal pure returns (TokenInterface[] memory) {
        TokenInterface[] memory _tokens = new TokenInterface[](length);
        for (uint i = 0; i < length; i++) {
            if (tokens[i] ==  getEthAddr()) {
                _tokens[i] = TokenInterface(getWethAddr());
            } else {
                _tokens[i] = TokenInterface(tokens[i]);
            }
        }
        return _tokens;
    }

    function getCtokenInterfaces(uint length, string[] memory tokenIds) internal view returns (CTokenInterface[] memory) {
        CTokenInterface[] memory _ctokens = new CTokenInterface[](length);
        for (uint i = 0; i < length; i++) {
            (address token, address cToken) = CompoundMappingInterface(getMappingAddr()).getMapping(tokenIds[i]);
            require(token != address(0) && cToken != address(0), "invalid token/ctoken address");
            _ctokens[i] = CTokenInterface(cToken);
        }
        return _ctokens;
    }
}

contract CompoundHelpers is Helpers {

    struct CompoundBorrowData {
        uint length;
        uint fee;
        Protocol target;
        CTokenInterface[] ctokens;
        TokenInterface[] tokens;
        uint[] amts;
        uint[] rateModes;
    }

    function _compEnterMarkets(uint length, CTokenInterface[] memory ctokens) internal {
        ComptrollerInterface troller = ComptrollerInterface(getComptrollerAddress());
        address[] memory _cTokens = new address[](length);

        for (uint i = 0; i < length; i++) {
            _cTokens[i] = address(ctokens[i]);
        }
        troller.enterMarkets(_cTokens);
    }

    function _compBorrowOne(
        uint fee,
        CTokenInterface ctoken,
        TokenInterface token,
        uint amt,
        Protocol target,
        uint rateMode
    ) internal returns (uint) {
        if (amt > 0) {
            address _token = address(token) == getWethAddr() ? getEthAddr() : address(token);

            if (amt == uint(-1)) {
                amt = getMaxBorrow(target, address(token), ctoken, rateMode);
            }

            (uint feeAmt, uint _amt) = calculateFee(amt, fee, true);

            require(ctoken.borrow(_amt) == 0, "borrow-failed-collateral?");
            transferFees(_token, feeAmt);
        }
        return amt;
    }

    function _compBorrow(
        CompoundBorrowData memory data
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](data.length);
        for (uint i = 0; i < data.length; i++) {
            finalAmts[i] = _compBorrowOne(
                data.fee, 
                data.ctokens[i], 
                data.tokens[i], 
                data.amts[i], 
                data.target, 
                data.rateModes[i]
            );
        }
        return finalAmts;
    }

    function _compDepositOne(uint fee, CTokenInterface ctoken, TokenInterface token, uint amt) internal {
        if (amt > 0) {
            address _token = address(token) == getWethAddr() ? getEthAddr() : address(token);

            (uint feeAmt, uint _amt) = calculateFee(amt, fee, false);

            if (_token != getEthAddr()) {
                token.approve(address(ctoken), _amt);
                require(ctoken.mint(_amt) == 0, "deposit-failed");
            } else {
                CETHInterface(address(ctoken)).mint{value:_amt}();
            }
            transferFees(_token, feeAmt);
        }
    }

    function _compDeposit(
        uint length,
        uint fee,
        CTokenInterface[] memory ctokens,
        TokenInterface[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            _compDepositOne(fee, ctokens[i], tokens[i], amts[i]);
        }
    }

    function _compWithdrawOne(CTokenInterface ctoken, TokenInterface token, uint amt) internal returns (uint) {
        if (amt > 0) {
            if (amt == uint(-1)) {
                bool isEth = address(token) == getWethAddr();
                uint initalBal = isEth ? address(this).balance : token.balanceOf(address(this));
                require(ctoken.redeem(ctoken.balanceOf(address(this))) == 0, "withdraw-failed");
                uint finalBal = isEth ? address(this).balance : token.balanceOf(address(this));
                amt = sub(finalBal, initalBal);
            } else {
                require(ctoken.redeemUnderlying(amt) == 0, "withdraw-failed");
            }
        }
        return amt;
    }

    function _compWithdraw(
        uint length,
        CTokenInterface[] memory ctokens,
        TokenInterface[] memory tokens,
        uint[] memory amts
    ) internal returns(uint[] memory) {
        uint[] memory finalAmts = new uint[](length);
        for (uint i = 0; i < length; i++) {
            finalAmts[i] = _compWithdrawOne(ctokens[i], tokens[i], amts[i]);
        }
        return finalAmts;
    }

    function _compPaybackOne(CTokenInterface ctoken, TokenInterface token, uint amt) internal returns (uint) {
        if (amt > 0) {
            if (amt == uint(-1)) {
                amt = ctoken.borrowBalanceCurrent(address(this));
            }
            if (address(token) != getWethAddr()) {
                token.approve(address(ctoken), amt);
                require(ctoken.repayBorrow(amt) == 0, "repay-failed.");
            } else {
                CETHInterface(address(ctoken)).repayBorrow{value:amt}();
            }
        }
        return amt;
    }

    function _compPayback(
        uint length,
        CTokenInterface[] memory ctokens,
        TokenInterface[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            _compPaybackOne(ctokens[i], tokens[i], amts[i]);
        }
    }
}

contract AaveV1Helpers is CompoundHelpers {

    struct AaveV1BorrowData {
        AaveV1Interface aave;
        uint length;
        uint fee;
        Protocol target;
        TokenInterface[] tokens;
        CTokenInterface[] ctokens;
        uint[] amts;
        uint[] borrowRateModes;
        uint[] paybackRateModes;
    }

    struct AaveV1DepositData {
        AaveV1Interface aave;
        AaveV1CoreInterface aaveCore;
        uint length;
        uint fee;
        TokenInterface[] tokens;
        uint[] amts;
    }

    function _aaveV1BorrowOne(
        AaveV1Interface aave,
        uint fee,
        Protocol target,
        TokenInterface token,
        CTokenInterface ctoken,
        uint amt,
        uint borrowRateMode,
        uint paybackRateMode
    ) internal returns (uint) {
        if (amt > 0) {

            address _token = address(token) == getWethAddr() ? getEthAddr() : address(token);

            if (amt == uint(-1)) {
                amt = getMaxBorrow(target, address(token), ctoken, paybackRateMode);
            }

            (uint feeAmt, uint _amt) = calculateFee(amt, fee, true);

            aave.borrow(_token, _amt, borrowRateMode, getReferralCode());
            transferFees(_token, feeAmt);
        }
        return amt;
    }

    function _aaveV1Borrow(
        AaveV1BorrowData memory data
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](data.length);
        for (uint i = 0; i < data.length; i++) {
            finalAmts[i] = _aaveV1BorrowOne(
                data.aave,
                data.fee,
                data.target,
                data.tokens[i],
                data.ctokens[i],
                data.amts[i],
                data.borrowRateModes[i],
                data.paybackRateModes[i]
            );
        }
        return finalAmts;
    }

    function _aaveV1DepositOne(
        AaveV1Interface aave,
        AaveV1CoreInterface aaveCore,
        uint fee,
        TokenInterface token,
        uint amt
    ) internal {
        if (amt > 0) {
            uint ethAmt;
            (uint feeAmt, uint _amt) = calculateFee(amt, fee, false);

            bool isEth = address(token) == getWethAddr();

            address _token = isEth ? getEthAddr() : address(token);

            if (isEth) {
                ethAmt = _amt;
            } else {
                token.approve(address(aaveCore), _amt);
            }

            transferFees(_token, feeAmt);

            aave.deposit{value:ethAmt}(_token, _amt, getReferralCode());

            if (!getIsColl(aave, _token))
                aave.setUserUseReserveAsCollateral(_token, true);
        }
    }

    function _aaveV1Deposit(
        AaveV1DepositData memory data
    ) internal {
        for (uint i = 0; i < data.length; i++) {
            _aaveV1DepositOne(
                data.aave,
                data.aaveCore,
                data.fee,
                data.tokens[i],
                data.amts[i]
            );
        }
    }

    function _aaveV1WithdrawOne(
        AaveV1Interface aave,
        AaveV1CoreInterface aaveCore,
        TokenInterface token,
        uint amt
    ) internal returns (uint) {
        if (amt > 0) {
            address _token = address(token) == getWethAddr() ? getEthAddr() : address(token);
            ATokenV1Interface atoken = ATokenV1Interface(aaveCore.getReserveATokenAddress(_token));
            if (amt == uint(-1)) {
                amt = getWithdrawBalance(aave, _token);
            }
            atoken.redeem(amt);
        }
        return amt;
    }

    function _aaveV1Withdraw(
        AaveV1Interface aave,
        AaveV1CoreInterface aaveCore,
        uint length,
        TokenInterface[] memory tokens,
        uint[] memory amts
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](length);
        for (uint i = 0; i < length; i++) {
            finalAmts[i] = _aaveV1WithdrawOne(aave, aaveCore, tokens[i], amts[i]);
        }
        return finalAmts;
    }

    function _aaveV1PaybackOne(
        AaveV1Interface aave,
        AaveV1CoreInterface aaveCore,
        TokenInterface token,
        uint amt
    ) internal returns (uint) {
        if (amt > 0) {
            uint ethAmt;

            bool isEth = address(token) == getWethAddr();

            address _token = isEth ? getEthAddr() : address(token);

            if (amt == uint(-1)) {
                (uint _amt, uint _fee) = getPaybackBalance(aave, _token);
                amt = _amt + _fee;
            }

            if (isEth) {
                ethAmt = amt;
            } else {
                token.approve(address(aaveCore), amt);
            }

            aave.repay{value:ethAmt}(_token, amt, payable(address(this)));
        }
        return amt;
    }

    function _aaveV1Payback(
        AaveV1Interface aave,
        AaveV1CoreInterface aaveCore,
        uint length,
        TokenInterface[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            _aaveV1PaybackOne(aave, aaveCore, tokens[i], amts[i]);
        }
    }
}

contract AaveV2Helpers is AaveV1Helpers {

    struct AaveV2BorrowData {
        AaveV2Interface aave;
        uint length;
        uint fee;
        Protocol target;
        TokenInterface[] tokens;
        CTokenInterface[] ctokens;
        uint[] amts;
        uint[] rateModes;
    }

    struct AaveV2PaybackData {
        AaveV2Interface aave;
        AaveV2DataProviderInterface aaveData;
        uint length;
        TokenInterface[] tokens;
        uint[] amts;
        uint[] rateModes;
    }

    struct AaveV2WithdrawData {
        AaveV2Interface aave;
        AaveV2DataProviderInterface aaveData;
        uint length;
        TokenInterface[] tokens;
        uint[] amts;
    }

    function _aaveV2BorrowOne(
        AaveV2Interface aave,
        uint fee,
        Protocol target,
        TokenInterface token,
        CTokenInterface ctoken,
        uint amt,
        uint rateMode
    ) internal returns (uint) {
        if (amt > 0) {
            bool isEth = address(token) == getWethAddr();
            
            address _token = isEth ? getEthAddr() : address(token);

            if (amt == uint(-1)) {
                amt = getMaxBorrow(target, _token, ctoken, rateMode);
            }

            (uint feeAmt, uint _amt) = calculateFee(amt, fee, true);

            aave.borrow(address(token), _amt, rateMode, getReferralCode(), address(this));
            convertWethToEth(isEth, token, amt);

            transferFees(_token, feeAmt);
        }
        return amt;
    }

    function _aaveV2Borrow(
        AaveV2BorrowData memory data
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](data.length);
        for (uint i = 0; i < data.length; i++) {
            finalAmts[i] = _aaveV2BorrowOne(
                data.aave,
                data.fee,
                data.target,
                data.tokens[i],
                data.ctokens[i],
                data.amts[i],
                data.rateModes[i]
            );
        }
        return finalAmts;
    }

    function _aaveV2DepositOne(
        AaveV2Interface aave,
        AaveV2DataProviderInterface aaveData,
        uint fee,
        TokenInterface token,
        uint amt
    ) internal {
        if (amt > 0) {
            (uint feeAmt, uint _amt) = calculateFee(amt, fee, false);

            bool isEth = address(token) == getWethAddr();
            address _token = isEth ? getEthAddr() : address(token);

            transferFees(_token, feeAmt);

            convertEthToWeth(isEth, token, _amt);

            token.approve(address(aave), _amt);

            aave.deposit(address(token), _amt, address(this), getReferralCode());

            if (!getIsCollV2(aaveData, address(token))) {
                aave.setUserUseReserveAsCollateral(address(token), true);
            }
        }
    }

    function _aaveV2Deposit(
        AaveV2Interface aave,
        AaveV2DataProviderInterface aaveData,
        uint length,
        uint fee,
        TokenInterface[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            _aaveV2DepositOne(aave, aaveData, fee, tokens[i], amts[i]);
        }
    }

    function _aaveV2WithdrawOne(
        AaveV2Interface aave,
        AaveV2DataProviderInterface aaveData,
        TokenInterface token,
        uint amt
    ) internal returns (uint _amt) {
        if (amt > 0) {
            bool isEth = address(token) == getWethAddr();

            aave.withdraw(address(token), amt, address(this));

            _amt = amt == uint(-1) ? getWithdrawBalanceV2(aaveData, address(token)) : amt;

            convertWethToEth(isEth, token, _amt);
        }
    }

    function _aaveV2Withdraw(
        AaveV2WithdrawData memory data
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](data.length);
        for (uint i = 0; i < data.length; i++) {
            finalAmts[i] = _aaveV2WithdrawOne(
                data.aave,
                data.aaveData,
                data.tokens[i],
                data.amts[i]
            );
        }
        return finalAmts;
    }

    function _aaveV2PaybackOne(
        AaveV2Interface aave,
        AaveV2DataProviderInterface aaveData,
        TokenInterface token,
        uint amt,
        uint rateMode
    ) internal returns (uint _amt) {
        if (amt > 0) {
            bool isEth = address(token) == getWethAddr();

            _amt = amt == uint(-1) ? getPaybackBalanceV2(aaveData, address(token), rateMode) : amt;

            convertEthToWeth(isEth, token, _amt);

            token.approve(address(aave), _amt);

            aave.repay(address(token), _amt, rateMode, address(this));
        }
    }

    function _aaveV2Payback(
        AaveV2PaybackData memory data
    ) internal {
        for (uint i = 0; i < data.length; i++) {
            _aaveV2PaybackOne(
                data.aave,
                data.aaveData,
                data.tokens[i],
                data.amts[i],
                data.rateModes[i]
            );
        }
    }
}

contract RefinanceResolver is AaveV2Helpers {

    struct RefinanceData {
        Protocol source;
        Protocol target;
        uint collateralFee;
        uint debtFee;
        address[] tokens;
        string[] ctokenIds;
        uint[] borrowAmts;
        uint[] withdrawAmts;
        uint[] borrowRateModes;
        uint[] paybackRateModes;
    }

    function refinance(RefinanceData calldata data) external payable {

        require(data.source != data.target, "source-and-target-unequal");

        uint length = data.tokens.length;

        require(data.borrowAmts.length == length, "length-mismatch");
        require(data.withdrawAmts.length == length, "length-mismatch");
        require(data.borrowRateModes.length == length, "length-mismatch");
        require(data.paybackRateModes.length == length, "length-mismatch");
        require(data.ctokenIds.length == length, "length-mismatch");

        AaveV2Interface aaveV2 = AaveV2Interface(getAaveV2Provider().getLendingPool());
        AaveV1Interface aaveV1 = AaveV1Interface(getAaveProvider().getLendingPool());
        AaveV1CoreInterface aaveCore = AaveV1CoreInterface(getAaveProvider().getLendingPoolCore());
        AaveV2DataProviderInterface aaveData = getAaveV2DataProvider();

        uint[] memory depositAmts;
        uint[] memory paybackAmts;

        TokenInterface[] memory tokens = getTokenInterfaces(length, data.tokens);
        CTokenInterface[] memory _ctokens = getCtokenInterfaces(length, data.ctokenIds);

        if (data.source == Protocol.Aave && data.target == Protocol.AaveV2) {
            AaveV2BorrowData memory _aaveV2BorrowData;

            _aaveV2BorrowData.aave = aaveV2;
            _aaveV2BorrowData.length = length;
            _aaveV2BorrowData.fee = data.debtFee;
            _aaveV2BorrowData.target = data.source;
            _aaveV2BorrowData.tokens = tokens;
            _aaveV2BorrowData.ctokens = _ctokens;
            _aaveV2BorrowData.amts = data.borrowAmts;
            _aaveV2BorrowData.rateModes = data.borrowRateModes;

            paybackAmts = _aaveV2Borrow(_aaveV2BorrowData);
            _aaveV1Payback(aaveV1, aaveCore, length, tokens, paybackAmts);
            depositAmts = _aaveV1Withdraw(aaveV1, aaveCore, length, tokens, data.withdrawAmts);
            _aaveV2Deposit(aaveV2, aaveData, length, data.collateralFee, tokens, depositAmts);
        } else if (data.source == Protocol.Aave && data.target == Protocol.Compound) {
            _compEnterMarkets(length, _ctokens);

            CompoundBorrowData memory _compoundBorrowData;

            _compoundBorrowData.length = length;
            _compoundBorrowData.fee = data.debtFee;
            _compoundBorrowData.target = data.source;
            _compoundBorrowData.ctokens = _ctokens;
            _compoundBorrowData.tokens = tokens;
            _compoundBorrowData.amts = data.borrowAmts;
            _compoundBorrowData.rateModes = data.borrowRateModes;

            paybackAmts = _compBorrow(_compoundBorrowData);
            
            _aaveV1Payback(aaveV1, aaveCore, length, tokens, paybackAmts);
            depositAmts = _aaveV1Withdraw(aaveV1, aaveCore, length, tokens, data.withdrawAmts);
            _compDeposit(length, data.collateralFee, _ctokens, tokens, depositAmts);
        } else if (data.source == Protocol.AaveV2 && data.target == Protocol.Aave) {

            AaveV1BorrowData memory _aaveV1BorrowData;
            AaveV2PaybackData memory _aaveV2PaybackData;
            AaveV2WithdrawData memory _aaveV2WithdrawData;

            {
                _aaveV1BorrowData.aave = aaveV1;
                _aaveV1BorrowData.length = length;
                _aaveV1BorrowData.fee = data.debtFee;
                _aaveV1BorrowData.target = data.source;
                _aaveV1BorrowData.tokens = tokens;
                _aaveV1BorrowData.ctokens = _ctokens;
                _aaveV1BorrowData.amts = data.borrowAmts;
                _aaveV1BorrowData.borrowRateModes = data.borrowRateModes;
                _aaveV1BorrowData.paybackRateModes = data.paybackRateModes;

                paybackAmts = _aaveV1Borrow(_aaveV1BorrowData);
            }
            
            {
                _aaveV2PaybackData.aave = aaveV2;
                _aaveV2PaybackData.aaveData = aaveData;
                _aaveV2PaybackData.length = length;
                _aaveV2PaybackData.tokens = tokens;
                _aaveV2PaybackData.amts = paybackAmts;
                _aaveV2PaybackData.rateModes = data.paybackRateModes;
                _aaveV2Payback(_aaveV2PaybackData);
            }

            {
                _aaveV2WithdrawData.aave = aaveV2;
                _aaveV2WithdrawData.aaveData = aaveData;
                _aaveV2WithdrawData.length = length;
                _aaveV2WithdrawData.tokens = tokens;
                _aaveV2WithdrawData.amts = data.withdrawAmts;
                depositAmts = _aaveV2Withdraw(_aaveV2WithdrawData);
            }
            {
                AaveV1DepositData memory _aaveV1DepositData;
                
                _aaveV1DepositData.aave = aaveV1;
                _aaveV1DepositData.aaveCore = aaveCore;
                _aaveV1DepositData.length = length;
                _aaveV1DepositData.fee = data.collateralFee;
                _aaveV1DepositData.tokens = tokens;
                _aaveV1DepositData.amts = depositAmts;

                _aaveV1Deposit(_aaveV1DepositData);
            }
        } else if (data.source == Protocol.AaveV2 && data.target == Protocol.Compound) {
            _compEnterMarkets(length, _ctokens);

            {
                CompoundBorrowData memory _compoundBorrowData;

                _compoundBorrowData.length = length;
                _compoundBorrowData.fee = data.debtFee;
                _compoundBorrowData.target = data.source;
                _compoundBorrowData.ctokens = _ctokens;
                _compoundBorrowData.tokens = tokens;
                _compoundBorrowData.amts = data.borrowAmts;
                _compoundBorrowData.rateModes = data.borrowRateModes;

                paybackAmts = _compBorrow(_compoundBorrowData);
            }

            AaveV2PaybackData memory _aaveV2PaybackData;

            _aaveV2PaybackData.aave = aaveV2;
            _aaveV2PaybackData.aaveData = aaveData;
            _aaveV2PaybackData.length = length;
            _aaveV2PaybackData.tokens = tokens;
            _aaveV2PaybackData.amts = paybackAmts;
            _aaveV2PaybackData.rateModes = data.paybackRateModes;
            
            _aaveV2Payback(_aaveV2PaybackData);

            {
                AaveV2WithdrawData memory _aaveV2WithdrawData;

                _aaveV2WithdrawData.aave = aaveV2;
                _aaveV2WithdrawData.aaveData = aaveData;
                _aaveV2WithdrawData.length = length;
                _aaveV2WithdrawData.tokens = tokens;
                _aaveV2WithdrawData.amts = data.withdrawAmts;
                depositAmts = _aaveV2Withdraw(_aaveV2WithdrawData);
            }
            _compDeposit(length, data.collateralFee, _ctokens, tokens, depositAmts);
        } else if (data.source == Protocol.Compound && data.target == Protocol.Aave) {

            AaveV1BorrowData memory _aaveV1BorrowData;

            _aaveV1BorrowData.aave = aaveV1;
            _aaveV1BorrowData.length = length;
            _aaveV1BorrowData.fee = data.debtFee;
            _aaveV1BorrowData.target = data.source;
            _aaveV1BorrowData.tokens = tokens;
            _aaveV1BorrowData.ctokens = _ctokens;
            _aaveV1BorrowData.amts = data.borrowAmts;
            _aaveV1BorrowData.borrowRateModes = data.borrowRateModes;
            _aaveV1BorrowData.paybackRateModes = data.paybackRateModes;
            
            paybackAmts = _aaveV1Borrow(_aaveV1BorrowData);
            {
            _compPayback(length, _ctokens, tokens, paybackAmts);
            depositAmts = _compWithdraw(length, _ctokens, tokens, data.withdrawAmts);
            }

            {
                AaveV1DepositData memory _aaveV1DepositData;
                
                _aaveV1DepositData.aave = aaveV1;
                _aaveV1DepositData.aaveCore = aaveCore;
                _aaveV1DepositData.length = length;
                _aaveV1DepositData.fee = data.collateralFee;
                _aaveV1DepositData.tokens = tokens;
                _aaveV1DepositData.amts = depositAmts;

                _aaveV1Deposit(_aaveV1DepositData);
            }
        } else if (data.source == Protocol.Compound && data.target == Protocol.AaveV2) {
            AaveV2BorrowData memory _aaveV2BorrowData;

            _aaveV2BorrowData.aave = aaveV2;
            _aaveV2BorrowData.length = length;
            _aaveV2BorrowData.fee = data.debtFee;
            _aaveV2BorrowData.target = data.source;
            _aaveV2BorrowData.tokens = tokens;
            _aaveV2BorrowData.ctokens = _ctokens;
            _aaveV2BorrowData.amts = data.borrowAmts;
            _aaveV2BorrowData.rateModes = data.borrowRateModes;
            
            paybackAmts = _aaveV2Borrow(_aaveV2BorrowData);
            _compPayback(length, _ctokens, tokens, paybackAmts);
            depositAmts = _compWithdraw(length, _ctokens, tokens, data.withdrawAmts);
            _aaveV2Deposit(aaveV2, aaveData, length, data.collateralFee, tokens, depositAmts);
        } else {
            revert("invalid-options");
        }
    }
}

contract ConnectRefinance is RefinanceResolver {
     /**
     * @dev Connector Details.
    */
    function connectorID() public pure returns(uint _type, uint _id) {
        (_type, _id) = (1, 96);
    }

    string public name = "Refinance-v1.2";
}