pragma solidity ^0.7.6;

library SafeInt256 {
    int256 private constant _INT256_MIN = type(int256).min;

    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        c = a * b;
        if (a == -1) require(b == 0 || c / b == a);
        else require(a == 0 || c / a == b);
    }

    function div(int256 a, int256 b) internal pure returns (int256 c) {
        require(!(b == -1 && a == _INT256_MIN)); // dev: int256 div overflow
        // NOTE: solidity will automatically revert on divide by zero
        c = a / b;
    }

    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        //  taken from uniswap v3
        require((z = x - y) <= x == (y >= 0));
    }

    function neg(int256 x) internal pure returns (int256 y) {
        return mul(-1, x);
    }

    function toInt(uint256 x) internal pure returns (int256 y) {
        require(x <= uint256(type(int256).max));
        return int256(x);
    }
}
