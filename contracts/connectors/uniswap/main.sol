pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract UniswapResolver is Helpers, Events {
    /**
     * @dev Deposit Liquidity.
     * @param tokenA tokenA address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param tokenB tokenB address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amtA tokenA amount.
     * @param unitAmt unit amount of amtB/amtA with slippage.
     * @param slippage slippage amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(
        address tokenA,
        address tokenB,
        uint amtA,
        uint unitAmt,
        uint slippage,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amtA);

        (uint _amtA, uint _amtB, uint _uniAmt) = _addLiquidity(
                                            tokenA,
                                            tokenB,
                                            _amt,
                                            unitAmt,
                                            slippage
                                        );
        setUint(setId, _uniAmt);
        
        _eventName = "LogDepositLiquidity(address,address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(tokenA, tokenB, _amtA, _amtB, _uniAmt, getId, setId);
    }

    /**
     * @dev Withdraw Liquidity.
     * @param tokenA tokenA address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param tokenB tokenB address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param uniAmt uni token amount.
     * @param unitAmtA unit amount of amtA/uniAmt with slippage.
     * @param unitAmtB unit amount of amtB/uniAmt with slippage.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setIds Set token amounts at this IDs in `InstaMemory` Contract.
    */
    function withdraw(
        address tokenA,
        address tokenB,
        uint uniAmt,
        uint unitAmtA,
        uint unitAmtB,
        uint getId,
        uint[] calldata setIds
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, uniAmt);

        (uint _amtA, uint _amtB, uint _uniAmt) = _removeLiquidity(
            tokenA,
            tokenB,
            _amt,
            unitAmtA,
            unitAmtB
        );

        setUint(setIds[0], _amtA);
        setUint(setIds[1], _amtB);
        
        _eventName = "LogWithdrawLiquidity(address,address,uint256,uint256,uint256,uint256,uint256[])";
        _eventParam = abi.encode(tokenA, tokenB, _amtA, _amtB, _uniAmt, getId, setIds);
    }

    /**
     * @dev Buy ETH/ERC20_Token.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param buyAmt buying token amount.
     * @param unitAmt unit amount of sellAmt/buyAmt with slippage.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function buy(
        address buyAddr,
        address sellAddr,
        uint buyAmt,
        uint unitAmt,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _buyAmt = getUint(getId, buyAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        address[] memory paths = getPaths(address(_buyAddr), address(_sellAddr));

        uint _slippageAmt = convert18ToDec(_sellAddr.decimals(),
            wmul(unitAmt, convertTo18(_buyAddr.decimals(), _buyAmt))
        );

        checkPair(paths);
        uint _expectedAmt = getExpectedSellAmt(paths, _buyAmt);
        require(_slippageAmt >= _expectedAmt, "Too much slippage");

        bool isEth = address(_sellAddr) == wethAddr;
        convertEthToWeth(isEth, _sellAddr, _expectedAmt);
        _sellAddr.approve(address(router), _expectedAmt);

        uint _sellAmt = router.swapTokensForExactTokens(
            _buyAmt,
            _expectedAmt,
            paths,
            address(this),
            block.timestamp + 1
        )[0];

        isEth = address(_buyAddr) == wethAddr;
        convertWethToEth(isEth, _buyAddr, _buyAmt);

        setUint(setId, _sellAmt);

        _eventName = "LogBuy(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
    }

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
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _sellAmt = getUint(getId, sellAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        address[] memory paths = getPaths(address(_buyAddr), address(_sellAddr));

        if (_sellAmt == uint(-1)) {
            _sellAmt = sellAddr == ethAddr ?
                address(this).balance :
                _sellAddr.balanceOf(address(this));
        }

        uint _slippageAmt = convert18ToDec(_buyAddr.decimals(),
            wmul(unitAmt, convertTo18(_sellAddr.decimals(), _sellAmt))
        );

        checkPair(paths);
        uint _expectedAmt = getExpectedBuyAmt(paths, _sellAmt);
        require(_slippageAmt <= _expectedAmt, "Too much slippage");

        bool isEth = address(_sellAddr) == wethAddr;
        convertEthToWeth(isEth, _sellAddr, _sellAmt);
        _sellAddr.approve(address(router), _sellAmt);

        uint _buyAmt = router.swapExactTokensForTokens(
            _sellAmt,
            _expectedAmt,
            paths,
            address(this),
            block.timestamp + 1
        )[1];

        isEth = address(_buyAddr) == wethAddr;
        convertWethToEth(isEth, _buyAddr, _buyAmt);

        setUint(setId, _buyAmt);

        _eventName = "LogSell(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
    }
}

contract ConnectV2UniswapV2 is UniswapResolver {
    string public name = "UniswapV2-v1";
}
