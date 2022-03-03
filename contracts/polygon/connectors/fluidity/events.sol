pragma solidity ^0.8.6;


contract Events {

event LogSupply(address indexed token_, uint amount_,uint itokenAmount_,uint getId,uint setId);

event LogWithdraw(address indexed token_, uint amt_,uint itokenAmount_,uint getId,uint setId);

event LogWithdrawItoken(address indexed token_, uint amt_,uint amount_,uint getId,uint setId);

event LogClaimReward(address indexed user_ , address  indexed token_ , uint[] updatedRewards_)


}