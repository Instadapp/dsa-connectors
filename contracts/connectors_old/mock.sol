pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

contract MockProtocol is Stores, DSMath {

    event LogMock(uint mockOne, uint mockTwo, uint getId, uint setId);

    // added two additional parameter (getId & setId) for external public facing functions
    function mockFunction(uint mockNumber, uint getId, uint setId) external payable {

        // protocol specific logics goes here

        // fetch value of specific id
        uint mockBalance = getUint(getId, mockNumber);

        // uses uint(-1)
        mockBalance = mockBalance == uint(-1) ? address(this).balance : mockNumber;

        // store new value for specific id
        setUint(setId, mockNumber);

        // common event standard
        emit LogMock(mockNumber, mockBalance, getId, setId);
        bytes32 eventCode = keccak256("LogMock(uint256,uint256,uint256,uint256)");
        bytes memory eventData = abi.encode(mockNumber, mockBalance, getId, setId);
        emitEvent(eventCode, eventData);
    }

}

contract ConnectMock is MockProtocol {
    string public name = "Mock-v1";
}