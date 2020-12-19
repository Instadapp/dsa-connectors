pragma solidity ^0.6.0;

import {Stores} from "../../common/stores.sol";

contract Events is Stores {
    event LogDeposit(
        address indexed token,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    function emitLogDeposit(
        address token,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    ) internal {
        emit LogDeposit(token, tokenAmt, getId, setId);
    }

    event LogWithdraw(
        address indexed token,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    function emitLogWithdraw(
        address token,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    ) internal {
        emit LogWithdraw(token, tokenAmt, getId, setId);
    }

    event LogBorrow(
        address indexed token,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    function emitLogBorrow(
        address token,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    ) internal {
        emit LogBorrow(token, tokenAmt, getId, setId);
    }

    event LogPayback(
        address indexed token,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    function emitLogPayback(
        address token,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    ) internal {
        emit LogPayback(token, tokenAmt, getId, setId);
    }

    event LogEnableCollateral(address[] tokens);

    function emitLogEnableCollateral(
        address[] memory tokens
    ) internal {
        emit LogEnableCollateral(tokens);
    }
}
