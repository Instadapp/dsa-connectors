pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

interface KyberInterface {
    function trade(
        address src,
        uint srcAmount,
        address dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    ) external payable returns (uint);

    function getExpectedRate(
        address src,
        address dest,
        uint srcQty
    ) external view returns (uint, uint);
}


contract KyberHelpers is DSMath, Stores  {
    /**
     * @dev Kyber Proxy Address
     */
    function getKyberAddr() internal pure returns (address) {
        return 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;
    }

    /**
     * @dev Referral Address
     */
    function getReferralAddr() internal pure returns (address) {
        return 0x7284a8451d9a0e7Dc62B3a71C0593eA2eC5c5638;
    }
}


contract KyberResolver is KyberHelpers {
    event LogSell(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    /**
     * @dev Sell ETH/ERC20_Token.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
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
    ) external payable
    {
        uint _sellAmt = getUint(getId, sellAmt);

        uint ethAmt;
        if (sellAddr == getEthAddr()) {
            _sellAmt = _sellAmt == uint(-1) ? address(this).balance : _sellAmt;
            ethAmt = _sellAmt;
        } else {
            TokenInterface sellContract = TokenInterface(sellAddr);
            _sellAmt = _sellAmt == uint(-1) ? sellContract.balanceOf(address(this)) : _sellAmt;
            sellContract.approve(getKyberAddr(), _sellAmt);
        }

        uint _buyAmt = KyberInterface(getKyberAddr()).trade.value(ethAmt)(
            sellAddr,
            _sellAmt,
            buyAddr,
            address(this),
            uint(-1),
            unitAmt,
            getReferralAddr()
        );

        setUint(setId, _buyAmt);

        emit LogSell(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        bytes32 eventCode = keccak256("LogSell(address,address,uint256,uint256,uint256,uint256)");
        bytes memory eventData = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        emitEvent(eventCode, eventData);
    }
}


contract ConnectKyber is KyberResolver {
    string public name = "Kyber-v1";
}