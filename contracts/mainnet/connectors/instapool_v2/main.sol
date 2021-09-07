pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Instapool.
 * @dev Inbuilt Flash Loan in DSA
 */

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { AccountInterface } from "./interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Stores } from "../../common/stores.sol";
import { Variables } from "./variables.sol";
import { Events } from "./events.sol";

contract LiquidityResolver is DSMath, Stores, Variables, Events {
    using SafeERC20 for IERC20;

    /**
     * @dev Borrow Flashloan and Cast spells.
     * @param token Token Address.
     * @param amt Token Amount.
     * @param route Flashloan source route. (0: dYdX(ETH,DAI,USDC only), 1: MakerDAO(DAI only), 2: Compound(All borrowable tokens in Compound), 3: AaveV2(All borrowable tokens in AaveV2))
     * @param data targets & data for cast.
     */
    function flashBorrowAndCast(
        address token,
        uint amt,
        uint route,
        bytes memory data
    ) external payable {
        AccountInterface(address(this)).enable(address(instaPool));
        (string[] memory _targets, bytes[] memory callDatas) = abi.decode(data, (string[], bytes[]));

        bytes memory callData = abi.encodeWithSignature("cast(string[],bytes[],address)", _targets, callDatas, address(instaPool));

        instaPool.initiateFlashLoan(token, amt, route, callData);

        emit LogFlashBorrow(token, amt);
        AccountInterface(address(this)).disable(address(instaPool));
    }

    /**
     * @dev Return token to InstaPool.
     * @param token Token Address.
     * @param amt Token Amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function flashPayback(
        address token,
        uint amt,
        uint getId,
        uint setId
    ) external payable {
        uint _amt = getUint(getId, amt);
        
        IERC20 tokenContract = IERC20(token);

        if (token == ethAddr) {
            Address.sendValue(payable(address(instaPool)), _amt);
        } else {
            tokenContract.safeTransfer(address(instaPool), _amt);
        }


        setUint(setId, _amt);

        emit LogFlashPayback(token, _amt);
    }
}

contract ConnectV2InstaPool is LiquidityResolver {
    string public name = "Instapool-v1.1";
}
