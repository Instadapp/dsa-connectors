pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";

import { IGUniRouter, IGUniPool, IERC20 } from "./interface.sol";


abstract contract Helpers is DSMath, Basic {

    IGUniRouter public constant gUniRouter = IGUniRouter(0x8CA6fa325bc32f86a12cC4964Edf1f71655007A7);

    struct DepositAndSwap {
        IGUniPool poolContract;
        IERC20 _token0;
        IERC20 _token1;
        uint amount0;
        uint amount1;
        uint mintAmount;
    }

    struct Deposit {
        IGUniPool poolContract;
        IERC20 _token0;
        IERC20 _token1;
        uint amount0In;
        uint amount1In;
        uint mintAmount;
    }
    
}
