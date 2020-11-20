pragma solidity ^0.6.0;

// import files from common directory
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";
import { TokenInterface } from "../common/interfaces.sol";

interface ICurve {
  function coins(int128 tokenId) external view returns (address token);
  function calc_token_amount(uint256[3] calldata amounts, bool deposit) external returns (uint256 amount);
  function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;
  function get_dy(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt) external returns (uint256 buyTokenAmt);
  function exchange(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt, uint256 minBuyToken) external;
  function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount) external;
  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external returns (uint256 amount);
}

contract CurveSBTCHelpers is Stores, DSMath{
  /**
  * @dev Return Curve Swap Address
  */
  function getCurveSwapAddr() internal pure returns (address) {
    return 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;
  }

  /**
  * @dev Return Curve Token Address
  */
  function getCurveTokenAddr() internal pure returns (address) {
    return 0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
  }

  function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
    amt = div(_amt, 10 ** (18 - _dec));
  }

  function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
    amt = mul(_amt, 10 ** (18 - _dec));
  }

  function getTokenI(address token) internal pure returns (int128 i) {
    if (token == address(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D)) {
      // RenBTC Token
      i = 0;
    } else if (token == address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)) {
      // WBTC Token
      i = 1;
    } else if (token == address(0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6)) {
      // SBTC Token
      i = 2;
    } else {
      revert("token-not-found.");
    }
  }
}

contract CurveSBTCProtocol is CurveSBTCHelpers {

  // Events
  event LogSell(
    address indexed buyToken,
    address indexed sellToken,
    uint256 buyAmt,
    uint256 sellAmt,
    uint256 getId,
    uint256 setId
  );
  event LogDeposit(address token, uint256 amt, uint256 mintAmt, uint256 getId, uint256 setId);
  event LogWithdraw(address token, uint256 amt, uint256 burnAmt, uint256 getId,  uint256 setId);

  /**
  * @dev Sell ERC20_Token.
  * @param buyAddr buying token address.
  * @param sellAddr selling token amount.
  * @param sellAmt selling token amount.
  * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
  * @param getId Get token amount at this ID from `InstaMemory` Contract.
  * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function sell(
    address buyAddr,
    address sellAddr,
    uint sellAmt,
    uint unitAmt,
    uint getId,
    uint setId
  ) external payable {
    uint _sellAmt = getUint(getId, sellAmt);
    ICurve curve = ICurve(getCurveSwapAddr());
    TokenInterface _buyToken = TokenInterface(buyAddr);
    TokenInterface _sellToken = TokenInterface(sellAddr);
    _sellAmt = _sellAmt == uint(-1) ? _sellToken.balanceOf(address(this)) : _sellAmt;
    _sellToken.approve(address(curve), _sellAmt);

    uint _slippageAmt = convert18ToDec(_buyToken.decimals(), wmul(unitAmt, convertTo18(_sellToken.decimals(), _sellAmt)));

    uint intialBal = _buyToken.balanceOf(address(this));
    curve.exchange(getTokenI(sellAddr), getTokenI(buyAddr), _sellAmt, _slippageAmt);
    uint finalBal = _buyToken.balanceOf(address(this));

    uint _buyAmt = sub(finalBal, intialBal);

    setUint(setId, _buyAmt);

    emit LogSell(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
    bytes32 _eventCode = keccak256("LogSell(address,address,uint256,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
    emitEvent(_eventCode, _eventParam);
  }

  /**
  * @dev Deposit Token.
  * @param token token address.
  * @param amt token amount.
  * @param unitAmt unit amount of curve_amt/token_amt with slippage.
  * @param getId Get token amount at this ID from `InstaMemory` Contract.
  * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function deposit(
    address token,
    uint amt,
    uint unitAmt,
    uint getId,
    uint setId
  ) external payable {
    uint256 _amt = getUint(getId, amt);
    TokenInterface tokenContract = TokenInterface(token);

    _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
    uint[3] memory _amts;
    _amts[uint(getTokenI(token))] = _amt;

    tokenContract.approve(getCurveSwapAddr(), _amt);

    uint _amt18 = convertTo18(tokenContract.decimals(), _amt);
    uint _slippageAmt = wmul(unitAmt, _amt18);

    TokenInterface curveTokenContract = TokenInterface(getCurveTokenAddr());
    uint initialCurveBal = curveTokenContract.balanceOf(address(this));

    ICurve(getCurveSwapAddr()).add_liquidity(_amts, _slippageAmt);

    uint finalCurveBal = curveTokenContract.balanceOf(address(this));

    uint mintAmt = sub(finalCurveBal, initialCurveBal);

    setUint(setId, mintAmt);

    emit LogDeposit(token, _amt, mintAmt, getId, setId);
    bytes32 _eventCode = keccak256("LogDeposit(address,uint256,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(token, _amt, mintAmt, getId, setId);
    emitEvent(_eventCode, _eventParam);
  }

  /**
  * @dev Withdraw Token.
  * @param token token address.
  * @param amt token amount.
  * @param unitAmt unit amount of curve_amt/token_amt with slippage.
  * @param getId Get token amount at this ID from `InstaMemory` Contract.
  * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function withdraw(
    address token,
    uint256 amt,
    uint256 unitAmt,
    uint getId,
    uint setId
  ) external payable {
    uint _amt = getUint(getId, amt);
    int128 tokenId = getTokenI(token);

    TokenInterface curveTokenContract = TokenInterface(getCurveTokenAddr());
    ICurve curveSwap = ICurve(getCurveSwapAddr());

    uint _curveAmt;
    uint[3] memory _amts;
    if (_amt == uint(-1)) {
      _curveAmt = curveTokenContract.balanceOf(address(this));
      _amt = curveSwap.calc_withdraw_one_coin(_curveAmt, tokenId);
      _amts[uint(tokenId)] = _amt;
    } else {
      _amts[uint(tokenId)] = _amt;
      _curveAmt = curveSwap.calc_token_amount(_amts, false);
    }

    uint _amt18 = convertTo18(TokenInterface(token).decimals(), _amt);
    uint _slippageAmt = wmul(unitAmt, _amt18);

    curveTokenContract.approve(address(curveSwap), 0);
    curveTokenContract.approve(address(curveSwap), _slippageAmt);

    curveSwap.remove_liquidity_imbalance(_amts, _slippageAmt);

    setUint(setId, _amt);

    emit LogWithdraw(token, _amt, _curveAmt, getId, setId);
    bytes32 _eventCode = keccak256("LogWithdraw(address,uint256,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(token, _amt, _curveAmt, getId, setId);
    emitEvent(_eventCode, _eventParam);
  }
}

contract ConnectSBTCCurve is CurveSBTCProtocol {
  string public name = "Curve-sbtc-v1";
}

