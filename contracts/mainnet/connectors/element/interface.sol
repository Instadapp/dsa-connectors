pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface ITranche {
    function underlying() external view returns (address);

    function deposit(uint256 _amount, address _destination)
        external
        returns (uint256, uint256);

    function withdrawPrincipal(uint256 _amount, address _destination)
        external
        returns (uint256);

    function withdrawInterest(uint256 _amount, address _destination)
        external
        returns (uint256);
}
