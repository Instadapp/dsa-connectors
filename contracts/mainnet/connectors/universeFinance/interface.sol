pragma solidity ^0.7.6;
pragma abicoder v2;

interface IUniverseAdapter {

    function depositProxy(
        address universeVault,
        uint256 amount0,
        uint256 amount1
    ) external returns(uint256, uint256);

}

interface IVaultV3 {

    function withdraw(uint256 share0, uint256 share1) external returns(uint256, uint256);
}
