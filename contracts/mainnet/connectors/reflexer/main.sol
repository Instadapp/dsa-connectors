pragma solidity ^0.7.0;

/**
 * @title Reflexer.
 * @dev Collateralized Borrowing.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { SafeEngineLike, TokenJoinInterface } from "./interface.sol";

abstract contract GebResolver is Helpers, Events {
    /**
     * @dev Open Safe
     * @notice Open a Reflexer Safe.
     * @param colType Type of Collateral.(eg: 'ETH-A')
    */
    function open(string calldata colType) external payable returns (string memory _eventName, bytes memory _eventParam) {
        bytes32 collateralType = stringToBytes32(colType);
        require(getCollateralJoinAddress(collateralType) != address(0), "wrong-col-type");
        uint256 safe = managerContract.openSAFE(collateralType, address(this));

        _eventName = "LogOpen(uint256,bytes32)";
        _eventParam = abi.encode(safe, collateralType);
    }

    /**
     * @dev Close Safe
     * @notice Close a Reflexer Safe.
     * @param safe Safe ID to close.
    */
    function close(uint256 safe) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _safe = getSafe(safe);
        (bytes32 collateralType, address handler) = getSafeData(_safe);
        (uint collateral, uint debt) = SafeEngineLike(managerContract.safeEngine()).safes(collateralType, handler);

        require(collateral == 0 && debt == 0, "safe-has-assets");
        require(managerContract.ownsSAFE(_safe) == address(this), "not-owner");

        managerContract.transferSAFEOwnership(_safe, giveAddr);

        _eventName = "LogClose(uint256,bytes32)";
        _eventParam = abi.encode(_safe, collateralType);
    }

    /**
     * @dev Deposit ETH/ERC20_Token Collateral.
     * @notice Deposit collateral to a Reflexer safe
     * @param safe Safe ID.
     * @param amt token amount to deposit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(
        uint256 safe,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _safe = getSafe(safe);
        (bytes32 collateralType, address handler) = getSafeData(_safe);

        address colAddr = getCollateralJoinAddress(collateralType);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);
        TokenInterface tokenContract = tokenJoinContract.collateral();

        if (isEth(address(tokenContract))) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            tokenContract.deposit{value: _amt}();
        } else {
            _amt = _amt == uint(-1) ?  tokenContract.balanceOf(address(this)) : _amt;
        }

        approve(tokenContract, address(colAddr), _amt);
        tokenJoinContract.join(address(this), _amt);

        SafeEngineLike(managerContract.safeEngine()).modifySAFECollateralization(
            collateralType,
            handler,
            address(this),
            address(this),
            toInt(convertTo18(tokenJoinContract.decimals(), _amt)),
            0
        );

        setUint(setId, _amt);

        _eventName = "LogDeposit(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_safe, collateralType, _amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token Collateral.
     * @notice Withdraw collateral from a Reflexer Safe
     * @param safe Safe ID.
     * @param amt token amount to withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdraw(
        uint256 safe,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _safe = getSafe(safe);
        (bytes32 collateralType, address handler) = getSafeData(_safe);

        address colAddr = getCollateralJoinAddress(collateralType);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);

        uint _amt18;
        if (_amt == uint(-1)) {
            (_amt18,) = SafeEngineLike(managerContract.safeEngine()).safes(collateralType, handler);
            _amt = convert18ToDec(tokenJoinContract.decimals(), _amt18);
        } else {
            _amt18 = convertTo18(tokenJoinContract.decimals(), _amt);
        }

        managerContract.modifySAFECollateralization(
            _safe,
            -toInt(_amt18),
            0
        );

        managerContract.transferCollateral(
            _safe,
            address(this),
            _amt18
        );

        TokenInterface tokenContract = tokenJoinContract.collateral();

        if (isEth(address(tokenContract))) {
            tokenJoinContract.exit(address(this), _amt);
            tokenContract.withdraw(_amt);
        } else {
            tokenJoinContract.exit(address(this), _amt);
        }

        setUint(setId, _amt);

        _eventName = "LogWithdraw(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_safe, collateralType, _amt, getId, setId);
    }

    /**
     * @dev Borrow Coin.
     * @notice Borrow Coin using a Reflexer safe
     * @param safe Safe ID.
     * @param amt token amount to borrow.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function borrow(
        uint256 safe,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _safe = getSafe(safe);
        (bytes32 collateralType, address handler) = getSafeData(_safe);

        SafeEngineLike safeEngineContract = SafeEngineLike(managerContract.safeEngine());

        managerContract.modifySAFECollateralization(
            _safe,
            0,
            _getBorrowAmt(
                address(safeEngineContract),
                handler,
                collateralType,
                _amt
            )
        );

        managerContract.transferInternalCoins(
            _safe,
            address(this),
            toRad(_amt)
        );

        if (safeEngineContract.safeRights(address(this), address(coinJoinContract)) == 0) {
            safeEngineContract.approveSAFEModification(address(coinJoinContract));
        }

        coinJoinContract.exit(address(this), _amt);

        setUint(setId, _amt);

        _eventName = "LogBorrow(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_safe, collateralType, _amt, getId, setId);
    }

    /**
     * @dev Payback borrowed Coin.
     * @notice Payback Coin debt owed by a Reflexer safe
     * @param safe Safe ID.
     * @param amt token amount to payback.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function payback(
        uint256 safe,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _safe = getSafe(safe);
        (bytes32 collateralType, address handler) = getSafeData(_safe);

        address safeEngine = managerContract.safeEngine();

        uint _maxDebt = _getSafeDebt(safeEngine, collateralType, handler);

        _amt = _amt == uint(-1) ? _maxDebt : _amt;

        require(_maxDebt >= _amt, "paying-excess-debt");

        approve(coinJoinContract.systemCoin(), address(coinJoinContract), _amt);
        coinJoinContract.join(handler, _amt);

        managerContract.modifySAFECollateralization(
            _safe,
            0,
            _getWipeAmt(
                safeEngine,
                SafeEngineLike(safeEngine).coinBalance(handler),
                handler,
                collateralType
            )
        );

        setUint(setId, _amt);

        _eventName = "LogPayback(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_safe, collateralType, _amt, getId, setId);
    }

    /**
     * @dev Withdraw leftover ETH/ERC20_Token after Liquidation.
     * @notice Withdraw leftover collateral after Liquidation.
     * @param safe Safe ID.
     * @param amt token amount to Withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdrawLiquidated(
        uint256 safe,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        (bytes32 collateralType, address handler) = getSafeData(safe);

        address colAddr = getCollateralJoinAddress(collateralType);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);

        uint _amt18;
        if (_amt == uint(-1)) {
            _amt18 = SafeEngineLike(managerContract.safeEngine()).tokenCollateral(collateralType, handler);
            _amt = convert18ToDec(tokenJoinContract.decimals(), _amt18);
        } else {
            _amt18 = convertTo18(tokenJoinContract.decimals(), _amt);
        }

        managerContract.transferCollateral(
            safe,
            address(this),
            _amt18
        );

        TokenInterface tokenContract = tokenJoinContract.collateral();
        tokenJoinContract.exit(address(this), _amt);
        if (isEth(address(tokenContract))) {
            tokenContract.withdraw(_amt);
        }

        setUint(setId, _amt);

        _eventName = "LogWithdrawLiquidated(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(safe, collateralType, _amt, getId, setId);
    }

    struct GebData {
        uint _safe;
        address colAddr;
        TokenJoinInterface tokenJoinContract;
        SafeEngineLike safeEngineContract;
        TokenInterface tokenContract;
    }

    /**
     * @dev Deposit ETH/ERC20_Token Collateral and Borrow Coin.
     * @notice Deposit collateral and borrow Coin.
     * @param safe Safe ID.
     * @param depositAmt token deposit amount to Withdraw.
     * @param borrowAmt token borrow amount to Withdraw.
     * @param getIdDeposit Get deposit token amount at this ID from `InstaMemory` Contract.
     * @param getIdBorrow Get borrow token amount at this ID from `InstaMemory` Contract.
     * @param setIdDeposit Set deposit token amount at this ID in `InstaMemory` Contract.
     * @param setIdBorrow Set borrow token amount at this ID in `InstaMemory` Contract.
    */
    function depositAndBorrow(
        uint256 safe,
        uint256 depositAmt,
        uint256 borrowAmt,
        uint256 getIdDeposit,
        uint256 getIdBorrow,
        uint256 setIdDeposit,
        uint256 setIdBorrow
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        GebData memory gebData;
        uint _amtDeposit = getUint(getIdDeposit, depositAmt);
        uint _amtBorrow = getUint(getIdBorrow, borrowAmt);

        gebData._safe = getSafe(safe);
        (bytes32 collateralType, address handler) = getSafeData(gebData._safe);

        gebData.colAddr = getCollateralJoinAddress(collateralType);
        gebData.tokenJoinContract = TokenJoinInterface(gebData.colAddr);
        gebData.safeEngineContract = SafeEngineLike(managerContract.safeEngine());
        gebData.tokenContract = gebData.tokenJoinContract.collateral();

        if (isEth(address(gebData.tokenContract))) {
            _amtDeposit = _amtDeposit == uint(-1) ? address(this).balance : _amtDeposit;
            gebData.tokenContract.deposit{value: _amtDeposit}();
        } else {
            _amtDeposit = _amtDeposit == uint(-1) ?  gebData.tokenContract.balanceOf(address(this)) : _amtDeposit;
        }

        approve(gebData.tokenContract, address(gebData.colAddr), _amtDeposit);
        gebData.tokenJoinContract.join(handler, _amtDeposit);

        managerContract.modifySAFECollateralization(
            gebData._safe,
            toInt(convertTo18(gebData.tokenJoinContract.decimals(), _amtDeposit)),
            _getBorrowAmt(
                address(gebData.safeEngineContract),
                handler,
                collateralType,
                _amtBorrow
            )
        );

        managerContract.transferInternalCoins(
            gebData._safe,
            address(this),
            toRad(_amtBorrow)
        );

        if (gebData.safeEngineContract.safeRights(address(this), address(coinJoinContract)) == 0) {
            gebData.safeEngineContract.approveSAFEModification(address(coinJoinContract));
        }

        coinJoinContract.exit(address(this), _amtBorrow);

        setUint(setIdDeposit, _amtDeposit);
        setUint(setIdBorrow, _amtBorrow);

        _eventName = "LogDepositAndBorrow(uint256,bytes32,uint256,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            gebData._safe,
            collateralType,
            _amtDeposit,
            _amtBorrow,
            getIdDeposit,
            getIdBorrow,
            setIdDeposit,
            setIdBorrow
        );
    }

    /**
     * @dev Exit Coin from handler.
     * @notice Exit Coin from handler.
     * @param safe Safe ID.
     * @param amt token amount to exit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function exit(
        uint256 safe,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        uint _safe = getSafe(safe);
        (bytes32 collateralType, address handler) = getSafeData(_safe);

        SafeEngineLike safeEngineContract = SafeEngineLike(managerContract.safeEngine());
        if(_amt == uint(-1)) {
            _amt = safeEngineContract.coinBalance(handler);
            _amt = _amt / 10 ** 27;
        }

        managerContract.transferInternalCoins(
            _safe,
            address(this),
            toRad(_amt)
        );

        if (safeEngineContract.safeRights(address(this), address(coinJoinContract)) == 0) {
            safeEngineContract.approveSAFEModification(address(coinJoinContract));
        }

        coinJoinContract.exit(address(this), _amt);

        setUint(setId, _amt);

        _eventName = "LogExit(uint256,bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_safe, collateralType, _amt, getId, setId);
    }

}

contract ConnectV2Reflexer is GebResolver {
    string public constant name = "Reflexer-v1";
}
