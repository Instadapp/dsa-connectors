pragma solidity ^0.7.0;

import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";

import {TokenInterface} from "../../common/interfaces.sol";
import {Stores} from "../../common/stores.sol";
import {erc20StablecoinInterface, maticStablecoinInterface} from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    address internal constant MAI = 0xa3Fa99A148fA48D14Ed51d610c367C61876997F1;

    function getVaultId(address vaultAddress, uint256 setId)
        public
        returns (uint256 vaultId)
    {
        erc20StablecoinInterface vault = erc20StablecoinInterface(vaultAddress);
        vaultId = vault.createVault();
        setUint(setId, vaultId);
    }

    function _destroyVault(
        address vaultAddress,
        uint256 vaultId,
        uint256 getId
    ) public returns (uint256 _vaultId) {
        erc20StablecoinInterface vault = erc20StablecoinInterface(vaultAddress);
        uint256 _vaultId = getUint(getId, vaultId);
        vault.destroyVault(_vaultId);
    }

    function _deposit(
        address token,
        address vaultAddress,
        uint256 vaultId,
        uint256 amt
    ) public {
        bool isEth = token == maticAddr;

        if (isEth) {
            maticStablecoinInterface vault = maticStablecoinInterface(
                vaultAddress
            );
            vault.depositCollateral{value: amt}(vaultId);
        } else {
            erc20StablecoinInterface vault = erc20StablecoinInterface(
                vaultAddress
            );
            TokenInterface tokenContract = TokenInterface(token);
            approve(tokenContract, address(vault), amt);
            vault.depositCollateral(vaultId, amt);
        }
    }

    function _withdraw(
        address token,
        address vaultAddress,
        uint256 vaultId,
        uint256 amt
    ) public returns (uint256 initialBal, uint256 finalBal) {
        bool isEth = token == maticAddr;

        if (isEth) {
            initialBal = address(this).balance;
            maticStablecoinInterface vault = maticStablecoinInterface(
                vaultAddress
            );

            vault.withdrawCollateral(vaultId, amt);
            finalBal = address(this).balance;
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            erc20StablecoinInterface vault = erc20StablecoinInterface(
                vaultAddress
            );

            initialBal = tokenContract.balanceOf(address(this));

            approve(tokenContract, address(vault), amt);
            vault.withdrawCollateral(vaultId, amt);
            finalBal = tokenContract.balanceOf(address(this));
        }
    }

    function _borrow(
        address vaultAddress,
        uint256 vaultId,
        uint256 amt
    ) public {
        erc20StablecoinInterface vault = erc20StablecoinInterface(vaultAddress);
        vault.borrowToken(vaultId, amt);
    }

    function _payback(
        address vaultAddress,
        uint256 vaultId,
        uint256 amt
    ) public {
        erc20StablecoinInterface vault = erc20StablecoinInterface(vaultAddress);

        TokenInterface tokenContract = TokenInterface(MAI);

        approve(tokenContract, address(vault), amt);

        vault.payBackToken(vaultId, amt);
    }
}
