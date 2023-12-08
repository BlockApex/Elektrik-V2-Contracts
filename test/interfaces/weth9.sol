// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function balanceOf(address account) external view returns (uint256);
 
}