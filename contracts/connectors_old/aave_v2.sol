pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// import files from common directory
import { TokenInterface , MemoryInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

interface AaveInterface {
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

interface AaveLendingPoolProviderInterface {
    function getLendingPool() external view returns (address);
}

// Aave Protocol Data Provider
interface AaveDataProviderInterface {
    function getReserveTokensAddresses(address _asset) external view returns (
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress
    );
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

interface AaveAddressProviderRegistryInterface {
    function getAddressesProvidersList() external view returns (address[] memory);
}

interface ATokenInterface {
    function balanceOf(address _user) external view returns(uint256);
}

contract AaveHelpers is DSMath, Stores {
    /**
     * @dev get Aave Lending Pool Provider
    */
    function getAaveProvider() internal pure returns (AaveLendingPoolProviderInterface) {
        return AaveLendingPoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5); //mainnet
        // return AaveLendingPoolProviderInterface(0x652B2937Efd0B5beA1c8d54293FC1289672AFC6b); //kovan
    }

    /**
     * @dev get Aave Protocol Data Provider
    */
    function getAaveDataProvider() internal pure returns (AaveDataProviderInterface) {
        return AaveDataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d); //mainnet
        // return AaveDataProviderInterface(0x744C1aaA95232EeF8A9994C4E0b3a89659D9AB79); //kovan
    }

    /**
     * @dev Return Weth address
    */
    function getWethAddr() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet WETH Address
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // Kovan WETH Address
    }

    /**
     * @dev get Referral Code
    */
    function getReferralCode() internal pure returns (uint16) {
        return 3228;
    }

    function getIsColl(AaveDataProviderInterface aaveData, address token, address user) internal view returns (bool isCol) {
        (, , , , , , , , isCol) = aaveData.getUserReserveData(token, user);
    }

    function convertEthToWeth(bool isEth, TokenInterface token, uint amount) internal {
        if(isEth) token.deposit.value(amount)();
    }

    function convertWethToEth(bool isEth, TokenInterface token, uint amount) internal {
       if(isEth) {
            token.approve(address(token), amount);
            token.withdraw(amount);
        }
    }

    function getPaybackBalance(AaveDataProviderInterface aaveData, address token, uint rateMode) internal view returns (uint) {
        (, uint stableDebt, uint variableDebt, , , , , , ) = aaveData.getUserReserveData(token, address(this));
        return rateMode == 1 ? stableDebt : variableDebt;
    }

    function getCollateralBalance(AaveDataProviderInterface aaveData, address token) internal view returns (uint bal) {
        (bal, , , , , , , ,) = aaveData.getUserReserveData(token, address(this));
    }
}

contract BasicResolver is AaveHelpers {
    event LogDeposit(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdraw(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogBorrow(address indexed token, uint256 tokenAmt, uint256 indexed rateMode, uint256 getId, uint256 setId);
    event LogPayback(address indexed token, uint256 tokenAmt, uint256 indexed rateMode, uint256 getId, uint256 setId);
    event LogEnableCollateral(address[] tokens);

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @param token token address to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to deposit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());
        AaveDataProviderInterface aaveData = getAaveDataProvider();

        bool isEth = token == getEthAddr();
        address _token = isEth ? getWethAddr() : token;

        TokenInterface tokenContract = TokenInterface(_token);

        if (isEth) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            convertEthToWeth(isEth, tokenContract, _amt);
        } else {
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
        }

        tokenContract.approve(address(aave), _amt);

        aave.deposit(_token, _amt, address(this), getReferralCode());

        if (!getIsColl(aaveData, _token, address(this))) {
            aave.setUserUseReserveAsCollateral(_token, true);
        }

        setUint(setId, _amt);

        emit LogDeposit(token, _amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @param token token address to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdraw(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());
        bool isEth = token == getEthAddr();
        address _token = isEth ? getWethAddr() : token;

        TokenInterface tokenContract = TokenInterface(_token);

        uint initialBal = tokenContract.balanceOf(address(this));
        aave.withdraw(_token, _amt, address(this));
        uint finalBal = tokenContract.balanceOf(address(this));

        _amt = sub(finalBal, initialBal);

        convertWethToEth(isEth, tokenContract, _amt);
        
        setUint(setId, _amt);

        emit LogWithdraw(token, _amt, getId, setId);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @param token token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to borrow.
     * @param rateMode type of borrow debt.(For Stable: 1, Variable: 2)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function borrow(address token, uint amt, uint rateMode, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());

        bool isEth = token == getEthAddr();
        address _token = isEth ? getWethAddr() : token;

        aave.borrow(_token, _amt, rateMode, getReferralCode(), address(this));
        convertWethToEth(isEth, TokenInterface(_token), _amt);

        setUint(setId, _amt);

        emit LogBorrow(token, _amt, rateMode, getId, setId);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @param token token address to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to payback.
     * @param rateMode type of borrow debt.(For Stable: 1, Variable: 2)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function payback(address token, uint amt, uint rateMode, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());
        AaveDataProviderInterface aaveData = getAaveDataProvider();

        bool isEth = token == getEthAddr();
        address _token = isEth ? getWethAddr() : token;

        TokenInterface tokenContract = TokenInterface(_token);

        _amt = _amt == uint(-1) ? getPaybackBalance(aaveData, _token, rateMode) : _amt;

        if (isEth) convertEthToWeth(isEth, tokenContract, _amt);

        tokenContract.approve(address(aave), _amt);

        aave.repay(_token, _amt, rateMode, address(this));

        setUint(setId, _amt);

        emit LogPayback(token, _amt, rateMode, getId, setId);
    }

    /**
     * @dev Enable collateral
     * @param tokens Array of tokens to enable collateral
    */
    function enableCollateral(address[] calldata tokens) external payable {
        uint _length = tokens.length;
        require(_length > 0, "0-tokens-not-allowed");

        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());
        AaveDataProviderInterface aaveData = getAaveDataProvider();

        for (uint i = 0; i < _length; i++) {
            address token = tokens[i];
            if (getCollateralBalance(aaveData, token) > 0 && !getIsColl(aaveData, token, address(this))) {
                aave.setUserUseReserveAsCollateral(token, true);
            }
        }

        emit LogEnableCollateral(tokens);
    }
}

contract ConnectAaveV2 is BasicResolver {
    string public name = "AaveV2-v1.1";
}
