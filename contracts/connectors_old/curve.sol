pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

interface ICurve {
  function underlying_coins(int128 tokenId) external view returns (address token);
  function calc_token_amount(uint256[4] calldata amounts, bool deposit) external returns (uint256 amount);
  function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;
  function get_dy(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt) external returns (uint256 buyTokenAmt);
  function exchange(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt, uint256 minBuyToken) external;
  function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;
}

interface ICurveZap {
  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external returns (uint256 amount);
}


contract CurveHelpers is Stores, DSMath {
  /**
  * @dev Return Curve Swap Address
  */
  function getCurveSwapAddr() internal pure returns (address) {
    return 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
  }

  /**
  * @dev Return Curve Token Address
  */
  function getCurveTokenAddr() internal pure returns (address) {
    return 0xC25a3A3b969415c80451098fa907EC722572917F;
  }

  /**
  * @dev Return Curve Zap Address
  */
  function getCurveZapAddr() internal pure returns (address) {
    return 0xFCBa3E75865d2d561BE8D220616520c171F12851;
  }

  function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
    amt = (_amt / 10 ** (18 - _dec));
  }

  function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
    amt = mul(_amt, 10 ** (18 - _dec));
  }

  function getTokenI(address token) internal pure returns (int128 i) {
    if (token == address(0x6B175474E89094C44Da98b954EedeAC495271d0F)) {
      // DAI Token
      i = 0;
    } else if (token == address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)) {
      // USDC Token
      i = 1;
    } else if (token == address(0xdAC17F958D2ee523a2206206994597C13D831ec7)) {
      // USDT Token
      i = 2;
    } else if (token == address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51)) {
      // sUSD Token
      i = 3;
    } else {
      revert("token-not-found.");
    }
  }

  function getTokenAddr(ICurve curve, uint256 i) internal view returns (address token) {
    token = curve.underlying_coins(int128(i));
    require(token != address(0), "token-not-found.");
  }
}

contract CurveProtocol is CurveHelpers {

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
  * @dev Sell Stable ERC20_Token.
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
    uint[4] memory _amts;
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
    ICurveZap curveZap = ICurveZap(getCurveZapAddr());
    ICurve curveSwap = ICurve(getCurveSwapAddr());

    uint _curveAmt;
    uint[4] memory _amts;
    if (_amt == uint(-1)) {
      _curveAmt = curveTokenContract.balanceOf(address(this));
      _amt = curveZap.calc_withdraw_one_coin(_curveAmt, tokenId);
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

contract ConnectCurve is CurveProtocol {
  string public name = "Curve-susd-v1.2";
}
