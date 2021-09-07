pragma solidity ^0.7.0;

/**
 * @title Yearn V2.
 * @dev Vaults & yield.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";
import { YearnV2Interface } from "./interface.sol";

abstract contract YearnResolver is Events, Basic {
    /**
     * @dev Deposit funds in the vault, issuing shares to recipient.
     * @notice This will deposit funds to a specific Yearn Vault.
     * @param vault The address of the vault to deposit funds into.
     * @param amt The amount of tokens to deposit.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of shares received.
    */
    function deposit(
        address vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        YearnV2Interface yearn = YearnV2Interface(vault);

        address want = yearn.token();
        bool iswETH = want == wethAddr;
        TokenInterface tokenContract = TokenInterface(want);

        if (iswETH) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            convertEthToWeth(iswETH, tokenContract, _amt);
        } else {
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
        }

        approve(tokenContract, vault, _amt);

        uint256 _shares = yearn.deposit(_amt, address(this));
        setUint(setId, _shares);

        _eventName = "LogDeposit(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(vault, _shares, _amt, getId, setId);
    }

    /**
     * @dev Withdraw shares from the vault.
     * @notice This will withdraw the share from a specific Yearn Vault.
     * @param vault The address of the vault to withdraw shares from.
     * @param amt The amount of shares to withdraw.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount want token redeemed.
    */
    function withdraw(
        address vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        YearnV2Interface vault = YearnV2Interface(vault);


        _amt = _amt == uint(-1) ? vault.balanceOf(address(this)) : _amt;
        uint256 _wantRedeemed = vault.withdraw(_amt, address(this));
        setUint(setId, _wantRedeemed);

        TokenInterface tokenContract = TokenInterface(vault.token());
        bool isWEth = vault.token() == wethAddr;
        convertWethToEth(isWEth, tokenContract, _amt);

        _eventName = "LogWithdraw(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(vault, _amt, _wantRedeemed, getId, setId);
    }
}

contract ConnectV2YearnV2 is YearnResolver {
    string public constant name = "YearnV2-v1.0";
}
