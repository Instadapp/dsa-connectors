pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
}

interface DydxFlashInterface {
    function initiateFlashLoan(address _token, uint256 _amount, bytes calldata data) external;
}

contract FlashLoanResolver is Stores {
    event LogDydxFlashLoan(address indexed token, uint256 tokenAmt);

    /**
        * @dev Return ethereum address
    */
    function getDydxLoanAddr() internal pure returns (address) {
        return address(0); // check9898 - change to dydx flash contract address
    }

    function getWethAddr() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    /**
     * @dev Borrow Flashloan and Cast spells.
     * @param token Token Address.
     * @param tokenAmt Token Amount.
     * @param data targets & data for cast.
     */
    function borrowAndCast(address token, uint tokenAmt, bytes memory data) public payable {
        AccountInterface(address(this)).enable(getDydxLoanAddr());

        address _token = token == getEthAddr() ? getWethAddr() : token;

        DydxFlashInterface(getDydxLoanAddr()).initiateFlashLoan(_token, tokenAmt, data);

        AccountInterface(address(this)).disable(getDydxLoanAddr());

        emit LogDydxFlashLoan(token, tokenAmt);
        bytes32 _eventCode = keccak256("LogDydxFlashLoan(address,uint256)");
        bytes memory _eventParam = abi.encode(token, tokenAmt);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

}


contract ConnectDydxFlashLoan is FlashLoanResolver {
    string public constant name = "dydx-flashloan-v1";
}
