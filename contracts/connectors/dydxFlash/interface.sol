pragma solidity ^0.7.0;

interface DydxFlashInterface {
    function initiateFlashLoan(address _token, uint256 _amount, bytes calldata data) external;
}
