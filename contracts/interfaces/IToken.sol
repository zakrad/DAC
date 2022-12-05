// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IToken {
    function getBalance(address account, uint256 id) external view returns(uint256);
    function getSupply(uint256 id) external view returns(uint256);
    function getCurrentId() external view returns(uint256);
    function burnFrom(address account, uint256 amount) external override(ERC20Burnable);
    function mint(address account, uint256 amount) external;
}