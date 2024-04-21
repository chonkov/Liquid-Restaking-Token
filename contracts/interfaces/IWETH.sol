// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IWETH {
    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function deposit() external payable;

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address user, uint256 amount) external returns (bool);
}
