pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;


import "./events.sol";
import "./helpers.sol";
import { TokenInterface } from "../../common/interfaces.sol";
abstract contract FluidityP1M2 is Events, Helpers {


function supply(address token_,
        uint amt,
        uint getId,
        uint setId
        ) public payable returns (string memory _eventName, bytes memory _eventParam) {
    
    uint amt_ = getUint(getId, amt);

    TokenInterface tokenContract = TokenInterface(token_);
    amt_ = amt_ == type(uint).max ? tokenContract.balanceOf(address(this)) : amt_;
    
    (uint itokenAmount_ )= p1m2.supply(token_,amt_ );

    setUint(setId, amt_ );

    _eventName = "LogSupply(address,uint,uint,uint,uint)";
    _eventParam = abi.encode(address(token_) , amt_ , itokenAmount_ , getId , setId);
}


function withdraw(address token_ , uint amount_, uint getId , uint setId) public payable returns (string memory _eventName , bytes memory _eventParam){

    uint amt_ = getUint(getId, amount_);
    TokenInterface tokenContract = TokenInterface(token_);
    amt_ = amt_ == type(uint).max ? tokenContract.balanceOf(address(this)) : amt_;

    (uint itokenAmount_) = p1m2.withdraw(token_,amt_);

    setUint(setId, amt_ );



    _eventName = "LogWithdraw(address,uint,uint,uint,uint)";
    _eventParam = abi.encode(address(token_) , amt_ , itokenAmount_ , getId , setId);


}

function  withdrawItoken(address token_, uint itokenAmount_ ,  uint getId,uint setId)  public payable returns (string memory _eventName , bytes memory _eventParam){

    uint amt_ = getUint(getId, itokenAmount_);
    TokenInterface tokenContract = TokenInterface(token_);
    amt_ = amt_ == type(uint).max ? tokenContract.balanceOf(address(this)) : amt_;

    (uint amount_) = p1m2.withdrawItoken(token_,amt_);

    setUint(setId, amt_ );



    _eventName = "LogWithdrawItoken(address,uint,uint,uint,uint)";
    _eventParam = abi.encode(address(token_) ,amt_, amount_ , getId , setId);

}


function claim(address user_, address token_, uint getId,uint setId) public payable returns (string memory _eventName , bytes memory _eventParam){


    uint[] memory updatedRewards_ = p1m2.claim(user_,token_);


    _eventName = "LogClaimReward(address,address,uint[])";
    _eventParam = abi.encode(address(user_),address(token_) , updatedRewards_);

}


}