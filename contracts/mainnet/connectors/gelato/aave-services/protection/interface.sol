// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
}

struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
}

interface LendingPoolInterface {
    function getReservesList() external view returns (address[] memory);

    function getReserveData(address asset)
        external
        view
        returns (ReserveData memory);
}

interface AaveServicesInterface {
    function submitTask(
        address _action,
        bytes memory _taskData,
        bool _isPermanent
    ) external;

    function cancelTask(address _action) external;

    function updateTask(
        address _action,
        bytes memory _data,
        bool _isPermanent
    ) external;

    function taskByUsersAction(address _user, address _action)
        external
        view
        returns (bytes32);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}