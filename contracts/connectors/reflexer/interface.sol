pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";

interface ManagerLike {
    function safeCan(address, uint, address) external view returns (uint);
    function collateralTypes(uint) external view returns (bytes32);
    function lastSAFEID(address) external view returns (uint);
    function safeCount(address) external view returns (uint);
    function ownsSAFE(uint) external view returns (address);
    function safes(uint) external view returns (address);
    function safeEngine() external view returns (address);
    function openSAFE(bytes32, address) external returns (uint);
    function transferSAFEOwnership(uint, address) external;
    function modifySAFECollateralization(uint, int, int) external;
    function transferCollateral(uint, address, uint) external;
    function transferInternalCoins(uint, address, uint) external;
}

interface SafeEngineLike {
    function can(address, address) external view returns (uint);
    function collateralTypes(bytes32) external view returns (uint, uint, uint, uint, uint);
    function coin(address) external view returns (uint);
    function safes(bytes32, address) external view returns (uint, uint);
    function modifySAFECollateralization(
        bytes32,
        address,
        address,
        address,
        int,
        int
    ) external;
    function approveSAFEModification(address) external;
    function transferInternalCoins(address, address, uint) external;
    function tokenCollateral(bytes32, address) external view returns (uint);
}

interface TokenJoinInterface {
    function decimals() external returns (uint);
    function collateral() external returns (TokenInterface);
    function join(address, uint) external payable;
    function exit(address, uint) external;
}

interface CoinJoinInterface {
    function safeEngine() external returns (SafeEngineLike);
    function coin() external returns (TokenInterface);
    function join(address, uint) external payable;
    function exit(address, uint) external;
}

interface TaxCollectorLike {
    function taxSingle(bytes32) external returns (uint);
}
