pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { VatLike, TokenJoinInterface } from "./interface.sol";

abstract contract MakerResolver is Helpers, Events {
    /**
     * @dev Open Vault
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
     * @dev Deposit ETH/ERC20_Token Collateral.
     * @param vault Vault ID.
     * @param amt token amount to deposit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
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

        tokenContract.approve(address(colAddr), _amt);
        tokenJoinContract.join(address(this), _amt);

        VatLike(managerContract.vat()).frob(
            ilk,
            urn,
            address(this),
            address(this),
            toInt(convertTo18(tokenJoinContract.dec(), _amt)),
            0
        );

        setUint(setId, _amt);

        _eventName = "LogDeposit(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_vault, ilk, _amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token Collateral.
     * @param vault Vault ID.
     * @param amt token amount to withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
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
     * @param vault Vault ID.
     * @param amt token amount to borrow.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
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
     * @param vault Vault ID.
     * @param amt token amount to payback.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
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

        uint _maxDebt = _getVaultDebt(vat, ilk, urn);

        _amt = _amt == uint(-1) ? _maxDebt : _amt;

        require(_maxDebt >= _amt, "paying-excess-debt");

        daiJoinContract.dai().approve(address(daiJoinContract), _amt);
        daiJoinContract.join(urn, _amt);

        managerContract.frob(
            _vault,
            0,
            _getWipeAmt(
                vat,
                VatLike(vat).dai(urn),
                urn,
                ilk
            )
        );

        setUint(setId, _amt);

        _eventName = "LogPayback(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_vault, ilk, _amt, getId, setId);
    }

    /**
     * @dev Withdraw leftover ETH/ERC20_Token after Liquidation.
     * @param vault Vault ID.
     * @param amt token amount to Withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
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
     * @param vault Vault ID.
     * @param depositAmt token deposit amount to Withdraw.
     * @param borrowAmt token borrow amount to Withdraw.
     * @param getIdDeposit Get deposit token amount at this ID from `InstaMemory` Contract.
     * @param getIdBorrow Get borrow token amount at this ID from `InstaMemory` Contract.
     * @param setIdDeposit Set deposit token amount at this ID in `InstaMemory` Contract.
     * @param setIdBorrow Set borrow token amount at this ID in `InstaMemory` Contract.
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

        makerData.tokenContract.approve(address(makerData.colAddr), _amtDeposit);
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
     * @param vault Vault ID.
     * @param amt token amount to exit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
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
     * @param amt DAI amount to deposit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
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

        daiJoinContract.dai().approve(address(daiJoinContract), _amt);
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
     * @param amt DAI amount to withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
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

contract ConnectV2Maker is MakerResolver {
    string public constant name = "MakerDao-v1";
}
