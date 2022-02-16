// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IERC20 {
    function balanceOf(address _holder) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}