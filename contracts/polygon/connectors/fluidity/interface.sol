pragma solidity ^0.8.0;

interface P1M2 {

    function supply(address token_, uint amount_) external  returns (uint itokenAmount_);
    function withdraw(address token_, uint amount_) external returns (uint itokenAmount_);
    function withdrawItoken(address token_, uint itokenAmount_) external returns (uint amount_);
    function claim(address user_, address token_) external returns (uint[] memory updatedRewards_);
}