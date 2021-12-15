pragma solidity ^0.7.0;

contract Events {

    event LogCreateVault(uint256 vaultId, address sender);
    event LogDestroyVault(uint256 vaultId, address sender);
    event LogDepositCollateral(uint256 vaultID, uint256 amount, uint256 getVaultId, uint256 getAmtId, uint256 setAmtId);
    event LogWithdrawCollateral(uint256 vaultID, uint256 amount, uint256 getVaultId, uint256 getAmtId, uint256 setAmtId);
    event LogBorrow(uint256 vaultID, uint256 amount, uint256 getVaultId, uint256 getAmtId, uint256 setAmtId);
    event LogPayBack(uint256 vaultID, uint256 amount, uint256 getVaultId, uint256 getAmtId, uint256 setAmtId);
}
