pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

interface ICurve {
  function underlying_coins(int128 tokenId) external view returns (address token);
  function get_dy(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt) external returns (uint256 buyTokenAmt);
  function exchange(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt, uint256 minBuyToken) external;
}

contract CurveHelpers is Stores, DSMath {
  /**
  * @dev Return Curve 3pool Swap Address
  */
  function getCurveSwapAddr() internal pure returns (address) {
    return 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
  }

  /**
  * @dev Return Curve 3pool Token Address
  */
  function getCurveTokenAddr() internal pure returns (address) {
    return 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
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
    } else {
      revert("token-not-found.");
    }
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
}

contract ConnectCurveThreePool is CurveProtocol {
  string public name = "Curve-3pool-v1.0";
}
