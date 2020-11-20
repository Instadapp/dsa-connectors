pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

interface ISwerve {
  function underlying_coins(int128 tokenId) external view returns (address token);
  function calc_token_amount(uint256[4] calldata amounts, bool deposit) external returns (uint256 amount);
  function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;
  function get_dy(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt) external returns (uint256 buyTokenAmt);
  function exchange(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt, uint256 minBuyToken) external;
  function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;
}

interface ISwerveZap {
  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external returns (uint256 amount);
}


contract SwerveHelpers is Stores, DSMath {
  /**
  * @dev Return Swerve Swap Address
  */
  function getSwerveSwapAddr() internal pure returns (address) {
    return 0x329239599afB305DA0A2eC69c58F8a6697F9F88d;
  }

  /**
  * @dev Return Swerve Token Address
  */
  function getSwerveTokenAddr() internal pure returns (address) {
    return 0x77C6E4a580c0dCE4E5c7a17d0bc077188a83A059;
  }

  /**
  * @dev Return Swerve Zap Address
  */
  function getSwerveZapAddr() internal pure returns (address) {
    return 0xa746c67eB7915Fa832a4C2076D403D4B68085431;
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
    } else if (token == address(0x0000000000085d4780B73119b644AE5ecd22b376)) {
      // TUSD Token
      i = 3;
    } else {
      revert("token-not-found.");
    }
  }
}

contract SwerveProtocol is SwerveHelpers {

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
    ISwerve swerve = ISwerve(getSwerveSwapAddr());
    TokenInterface _buyToken = TokenInterface(buyAddr);
    TokenInterface _sellToken = TokenInterface(sellAddr);
    _sellAmt = _sellAmt == uint(-1) ? _sellToken.balanceOf(address(this)) : _sellAmt;
    _sellToken.approve(address(swerve), _sellAmt);

    uint _slippageAmt = convert18ToDec(_buyToken.decimals(), wmul(unitAmt, convertTo18(_sellToken.decimals(), _sellAmt)));

    uint intialBal = _buyToken.balanceOf(address(this));
    swerve.exchange(getTokenI(sellAddr), getTokenI(buyAddr), _sellAmt, _slippageAmt);
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
    * @param unitAmt unit amount of swerve_amt/token_amt with slippage.
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

    tokenContract.approve(getSwerveSwapAddr(), _amt);

    uint _amt18 = convertTo18(tokenContract.decimals(), _amt);
    uint _slippageAmt = wmul(unitAmt, _amt18);

    TokenInterface swerveTokenContract = TokenInterface(getSwerveTokenAddr());
    uint initialSwerveBal = swerveTokenContract.balanceOf(address(this));

    ISwerve(getSwerveSwapAddr()).add_liquidity(_amts, _slippageAmt);

    uint finalSwerveBal = swerveTokenContract.balanceOf(address(this));

    uint mintAmt = sub(finalSwerveBal, initialSwerveBal);

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
    * @param unitAmt unit amount of swerve_amt/token_amt with slippage.
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

    TokenInterface swerveTokenContract = TokenInterface(getSwerveTokenAddr());
    ISwerveZap swerveZap = ISwerveZap(getSwerveZapAddr());
    ISwerve swerveSwap = ISwerve(getSwerveSwapAddr());

    uint _swerveAmt;
    uint[4] memory _amts;
    if (_amt == uint(-1)) {
      _swerveAmt = swerveTokenContract.balanceOf(address(this));
      _amt = swerveZap.calc_withdraw_one_coin(_swerveAmt, tokenId);
      _amts[uint(tokenId)] = _amt;
    } else {
      _amts[uint(tokenId)] = _amt;
      _swerveAmt = swerveSwap.calc_token_amount(_amts, false);
    }


    uint _amt18 = convertTo18(TokenInterface(token).decimals(), _amt);
    uint _slippageAmt = wmul(unitAmt, _amt18);

    swerveTokenContract.approve(address(swerveSwap), 0);
    swerveTokenContract.approve(address(swerveSwap), _slippageAmt);

    swerveSwap.remove_liquidity_imbalance(_amts, _slippageAmt);

    setUint(setId, _amt);

    emit LogWithdraw(token, _amt, _swerveAmt, getId, setId);
    bytes32 _eventCode = keccak256("LogWithdraw(address,uint256,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(token, _amt, _swerveAmt, getId, setId);
    emitEvent(_eventCode, _eventParam);
  }

}

contract ConnectSwerve is SwerveProtocol {
  string public name = "Swerve-swUSD-v1.0";
}
