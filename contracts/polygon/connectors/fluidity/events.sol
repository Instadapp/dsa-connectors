pragma solidity ^0.8.0;


contract Events {

event LogSupply(address token_, uint amount_,uint itokenAmount_,uint getId,uint setId);

event LogWithdraw(address token_, uint amt_,uint itokenAmount_,uint getId,uint setId);

event LogWithdrawItoken(address token_, uint amt_,uint amount_,uint getId,uint setId);

event LogClaimReward(address user_, address token_,uint[] updatedRewards_)


}