pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface MemoryInterface {
    function getUint(uint _id) external returns (uint _num);
    function setUint(uint _id, uint _val) external;
}

contract DSMath {
    uint256 constant WAD = 10 ** 18;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
}

contract Setup is DSMath {

     /**
     * @dev Return InstAaMemory Address.
     */
    function getMemoryAddr() internal pure returns (address) {
        return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F;
    }

    /**
     * @dev Get Uint value from InstaMemory Contract.
    */
    function getUint(uint getId, uint val) internal returns (uint returnVal) {
        returnVal = getId == 0 ? val : MemoryInterface(getMemoryAddr()).getUint(getId);
    }

    /**
     * @dev Set Uint value in InstaMemory Contract.
    */
    function setUint(uint setId, uint val) internal {
        if (setId != 0) MemoryInterface(getMemoryAddr()).setUint(setId, val);
    }

     /**
     * @dev Connector ID and Type. TODO: change.
     */
    function connectorID() public pure returns(uint _type, uint _id) {
        (_type, _id) = (1, 37);
    }

}


contract FeeResolver is Setup {

    /**
     * @dev Calculate fee
     */
    function calculateFee(uint amount, uint fee, uint getId, uint setId, uint setIdFee) external payable {
        uint _amt = getUint(getId, amount);

        uint feeAmt = wmul(_amt, fee);

        uint totalAmt = add(_amt, feeAmt);

        setUint(setId, totalAmt);
        setUint(setIdFee, feeAmt);
    }
}


contract ConnectFee is FeeResolver {
    string public constant name = "Fee-v1";
}