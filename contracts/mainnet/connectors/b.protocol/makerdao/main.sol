pragma solidity ^0.7.0;

/**
 * @title MakerDAO.
 * @dev Collateralized Borrowing.
 */

import { TokenInterface, AccountInterface } from "./../../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { VatLike, TokenJoinInterface } from "./interface.sol";

abstract contract BMakerResolver is Helpers, Events {
    /**
     * @dev Open Vault
     * @notice Open a MakerDAO Vault
     * @param colType Type of Collateral.(eg: 'ETH-A')
    */
    function open(string calldata colType) external payable returns (string memory _eventName, bytes memory _eventParam) {
        bytes32 ilk = stringToBytes32(colType);
        require(instaMapping.gemJoinMapping(ilk) != address(0), "wrong-col-type");
        uint256 vault = managerContract.open(ilk, address(this));

        _eventName = "LogOpen(uint256,bytes32)";
        _eventParam = abi.encode(vault, ilk);
    }

    /**
     * @dev Close Vault
     * @notice Close a MakerDAO Vault
     * @param vault Vault ID to close.
    */
    function close(uint256 vault) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _vault = getVault(vault);
        (bytes32 ilk, address urn) = getVaultData(_vault);
        (uint ink, uint art) = VatLike(managerContract.vat()).urns(ilk, urn);

        require(ink == 0 && art == 0, "vault-has-assets");
        require(managerContract.owns(_vault) == address(this), "not-owner");

        managerContract.give(_vault, giveAddr);

        _eventName = "LogClose(uint256,bytes32)";
        _eventParam = abi.encode(_vault, ilk);
    }

    /**
     * @dev Transfer Vault
     * @notice Transfer a MakerDAO Vault to "nextOwner"
     * @param vault Vault ID to close.
     * @param nextOwner Address of the next owner of the vault.
    */
    function transfer(
        uint vault,
        address nextOwner
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(AccountInterface(address(this)).isAuth(nextOwner), "nextOwner-is-not-auth");

        uint256 _vault = getVault(vault);
        (bytes32 ilk,) = getVaultData(_vault);

        require(managerContract.owns(_vault) == address(this), "not-owner");

        managerContract.give(_vault, nextOwner);

        _eventName = "LogTransfer(uint256,bytes32,address)";
        _eventParam = abi.encode(_vault, ilk, nextOwner);
    }

    /**
     * @dev Deposit ETH/ERC20_Token Collateral.
     * @notice Deposit collateral to a MakerDAO vault
     * @param vault Vault ID. (Use 0 for last opened vault)
     * @param amt The amount of tokens to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function deposit(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _vault = getVault(vault);
        (bytes32 ilk, address urn) = getVaultData(_vault);

        address colAddr = instaMapping.gemJoinMapping(ilk);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);
        TokenInterface tokenContract = tokenJoinContract.gem();

        if (isEth(address(tokenContract))) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            tokenContract.deposit{value: _amt}();
        } else {
            _amt = _amt == uint(-1) ?  tokenContract.balanceOf(address(this)) : _amt;
        }

        approve(tokenContract, address(colAddr), _amt);
        tokenJoinContract.join(urn, _amt);

        managerContract.frob(
            _vault,
            toInt(convertTo18(tokenJoinContract.dec(), _amt)),
            0
        );

        setUint(setId, _amt);

        _eventName = "LogDeposit(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_vault, ilk, _amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token Collateral.
     * @notice Withdraw collateral from a MakerDAO vault
     * @param vault Vault ID. (Use 0 for last opened vault)
     * @param amt The amount of tokens to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdraw(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _vault = getVault(vault);
        (bytes32 ilk, address urn) = getVaultData(_vault);

        address colAddr = instaMapping.gemJoinMapping(ilk);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);

        uint _amt18;
        if (_amt == uint(-1)) {
            (_amt18,) = VatLike(managerContract.vat()).urns(ilk, urn);
            _amt = convert18ToDec(tokenJoinContract.dec(), _amt18);
        } else {
            _amt18 = convertTo18(tokenJoinContract.dec(), _amt);
        }

        managerContract.frob(
            _vault,
            -toInt(_amt18),
            0
        );

        managerContract.flux(
            _vault,
            address(this),
            _amt18
        );

        TokenInterface tokenContract = tokenJoinContract.gem();

        if (isEth(address(tokenContract))) {
            tokenJoinContract.exit(address(this), _amt);
            tokenContract.withdraw(_amt);
        } else {
            tokenJoinContract.exit(address(this), _amt);
        }

        setUint(setId, _amt);

        _eventName = "LogWithdraw(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_vault, ilk, _amt, getId, setId);
    }

    /**
     * @dev Borrow DAI.
     * @notice Borrow DAI using a MakerDAO vault
     * @param vault Vault ID. (Use 0 for last opened vault)
     * @param amt The amount of DAI to borrow.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of DAI borrowed.
    */
    function borrow(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _vault = getVault(vault);
        (bytes32 ilk, address urn) = getVaultData(_vault);

        VatLike vatContract = VatLike(managerContract.vat());

        managerContract.frob(
            _vault,
            0,
            _getBorrowAmt(
                address(vatContract),
                urn,
                ilk,
                _amt
            )
        );

        managerContract.move(
            _vault,
            address(this),
            toRad(_amt)
        );

        if (vatContract.can(address(this), address(daiJoinContract)) == 0) {
            vatContract.hope(address(daiJoinContract));
        }

        daiJoinContract.exit(address(this), _amt);

        setUint(setId, _amt);

        _eventName = "LogBorrow(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_vault, ilk, _amt, getId, setId);
    }

    /**
     * @dev Payback borrowed DAI.
     * @notice Payback DAI debt owed by a MakerDAO vault
     * @param vault Vault ID. (Use 0 for last opened vault)
     * @param amt The amount of DAI to payback. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of DAI paid back.
    */
    function payback(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _vault = getVault(vault);
        (bytes32 ilk, address urn) = getVaultData(_vault);

        address vat = managerContract.vat();

        uint _maxDebt = _getVaultDebt(vat, ilk, urn, vault);

        _amt = _amt == uint(-1) ? _maxDebt : _amt;

        require(_maxDebt >= _amt, "paying-excess-debt");

        approve(daiJoinContract.dai(), address(daiJoinContract), _amt);
        daiJoinContract.join(urn, _amt);

        managerContract.frob(
            _vault,
            0,
            _getWipeAmt(
                vat,
                VatLike(vat).dai(urn),
                urn,
                ilk,
                _vault
            )
        );

        setUint(setId, _amt);

        _eventName = "LogPayback(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_vault, ilk, _amt, getId, setId);
    }

    /**
     * @dev Withdraw leftover ETH/ERC20_Token after Liquidation.
     * @notice Withdraw leftover collateral after Liquidation.
     * @param vault Vault ID. (Use 0 for last opened vault)
     * @param amt token amount to Withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of collateral withdrawn.
    */
    function withdrawLiquidated(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        (bytes32 ilk, address urn) = getVaultData(vault);

        address colAddr = instaMapping.gemJoinMapping(ilk);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);

        uint _amt18;
        if (_amt == uint(-1)) {
            _amt18 = VatLike(managerContract.vat()).gem(ilk, urn);
            _amt = convert18ToDec(tokenJoinContract.dec(), _amt18);
        } else {
            _amt18 = convertTo18(tokenJoinContract.dec(), _amt);
        }

        managerContract.flux(
            vault,
            address(this),
            _amt18
        );

        TokenInterface tokenContract = tokenJoinContract.gem();
        tokenJoinContract.exit(address(this), _amt);
        if (isEth(address(tokenContract))) {
            tokenContract.withdraw(_amt);
        }

        setUint(setId, _amt);

        _eventName = "LogWithdrawLiquidated(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(vault, ilk, _amt, getId, setId);
    }

    struct MakerData {
        uint _vault;
        address colAddr;
        TokenJoinInterface tokenJoinContract;
        VatLike vatContract;
        TokenInterface tokenContract;
    }
    /**
     * @dev Deposit ETH/ERC20_Token Collateral and Borrow DAI.
     * @notice Deposit collateral and borrow DAI.
     * @param vault Vault ID. (Use 0 for last opened vault)
     * @param depositAmt The amount of tokens to deposit. (For max: `uint256(-1)`)
     * @param borrowAmt The amount of DAI to borrow.
     * @param getIdDeposit ID to retrieve depositAmt.
     * @param getIdBorrow ID to retrieve borrowAmt.
     * @param setIdDeposit ID stores the amount of tokens deposited.
     * @param setIdBorrow ID stores the amount of DAI borrowed.
    */
    function depositAndBorrow(
        uint256 vault,
        uint256 depositAmt,
        uint256 borrowAmt,
        uint256 getIdDeposit,
        uint256 getIdBorrow,
        uint256 setIdDeposit,
        uint256 setIdBorrow
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        MakerData memory makerData;
        uint _amtDeposit = getUint(getIdDeposit, depositAmt);
        uint _amtBorrow = getUint(getIdBorrow, borrowAmt);

        makerData._vault = getVault(vault);
        (bytes32 ilk, address urn) = getVaultData(makerData._vault);

        makerData.colAddr = instaMapping.gemJoinMapping(ilk);
        makerData.tokenJoinContract = TokenJoinInterface(makerData.colAddr);
        makerData.vatContract = VatLike(managerContract.vat());
        makerData.tokenContract = makerData.tokenJoinContract.gem();

        if (isEth(address(makerData.tokenContract))) {
            _amtDeposit = _amtDeposit == uint(-1) ? address(this).balance : _amtDeposit;
            makerData.tokenContract.deposit{value: _amtDeposit}();
        } else {
            _amtDeposit = _amtDeposit == uint(-1) ?  makerData.tokenContract.balanceOf(address(this)) : _amtDeposit;
        }

        approve(makerData.tokenContract, address(makerData.colAddr), _amtDeposit);
        makerData.tokenJoinContract.join(urn, _amtDeposit);

        managerContract.frob(
            makerData._vault,
            toInt(convertTo18(makerData.tokenJoinContract.dec(), _amtDeposit)),
            _getBorrowAmt(
                address(makerData.vatContract),
                urn,
                ilk,
                _amtBorrow
            )
        );

        managerContract.move(
            makerData._vault,
            address(this),
            toRad(_amtBorrow)
        );

        if (makerData.vatContract.can(address(this), address(daiJoinContract)) == 0) {
            makerData.vatContract.hope(address(daiJoinContract));
        }

        daiJoinContract.exit(address(this), _amtBorrow);

        setUint(setIdDeposit, _amtDeposit);
        setUint(setIdBorrow, _amtBorrow);

        _eventName = "LogDepositAndBorrow(uint256,bytes32,uint256,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            makerData._vault,
            ilk,
            _amtDeposit,
            _amtBorrow,
            getIdDeposit,
            getIdBorrow,
            setIdDeposit,
            setIdBorrow
        );
    }

    /**
     * @dev Exit DAI from urn.
     * @notice Exit DAI from urn.
     * @param vault Vault ID. (Use 0 for last opened vault)
     * @param amt The amount of DAI to exit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of DAI exited.
    */
    function exitDai(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _vault = getVault(vault);
        (bytes32 ilk, address urn) = getVaultData(_vault);

        VatLike vatContract = VatLike(managerContract.vat());
        if(_amt == uint(-1)) {
            _amt = vatContract.dai(urn);
            _amt = _amt / 10 ** 27;
        }

        managerContract.move(
            _vault,
            address(this),
            toRad(_amt)
        );

        if (vatContract.can(address(this), address(daiJoinContract)) == 0) {
            vatContract.hope(address(daiJoinContract));
        }

        daiJoinContract.exit(address(this), _amt);

        setUint(setId, _amt);

        _eventName = "LogExitDai(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_vault, ilk, _amt, getId, setId);
    }

    /**
     * @dev Deposit DAI in DSR.
     * @notice Deposit DAI in DSR.
     * @param amt The amount of DAI to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of DAI deposited.
    */
    function depositDai(
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        _amt = _amt == uint(-1) ?
            daiJoinContract.dai().balanceOf(address(this)) :
            _amt;

        VatLike vat = daiJoinContract.vat();
        uint chi = potContract.drip();

        approve(daiJoinContract.dai(), address(daiJoinContract), _amt);
        daiJoinContract.join(address(this), _amt);
        if (vat.can(address(this), address(potContract)) == 0) {
            vat.hope(address(potContract));
        }

        potContract.join(mul(_amt, RAY) / chi);
        setUint(setId, _amt);

        _eventName = "LogDepositDai(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }

    /**
     * @dev Withdraw DAI from DSR.
     * @notice Withdraw DAI from DSR.
     * @param amt The amount of DAI to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of DAI withdrawn.
    */
    function withdrawDai(
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        VatLike vat = daiJoinContract.vat();

        uint chi = potContract.drip();
        uint pie;
        if (_amt == uint(-1)) {
            pie = potContract.pie(address(this));
            _amt = mul(chi, pie) / RAY;
        } else {
            pie = mul(_amt, RAY) / chi;
        }

        potContract.exit(pie);

        uint bal = vat.dai(address(this));
        if (vat.can(address(this), address(daiJoinContract)) == 0) {
            vat.hope(address(daiJoinContract));
        }
        daiJoinContract.exit(
            address(this),
            bal >= mul(_amt, RAY) ? _amt : bal / RAY
        );

        setUint(setId, _amt);

        _eventName = "LogWithdrawDai(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }
}

contract ConnectV2BMakerDAO is BMakerResolver {
    string public constant name = "B.MakerDAO-v1.0";
}
