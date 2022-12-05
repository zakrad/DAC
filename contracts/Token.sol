// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./libraries/MathLib.sol";


contract MyToken is ERC20, ERC20Snapshot, Ownable, ERC20Permit, ERC20Votes, ERC20Burnable {
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {}

    function snapshot() public onlyOwner {
        _snapshot();
    }
    
    function getCurrentId() external view returns(uint256) {
        return _getCurrentSnapshotId();
    }

    function getBalance(address account, uint256 id) external view returns(uint256) {
        return balanceOfAt(account, id);
    }

    function getSupply(uint256 id) external view returns(uint256) {
        return totalSupplyAt(id);
    }

    function buyPrice(uint _dS) public view returns(uint) {
        return MathLib.buyIntegral(totalSupply(), _dS);
    }

    function sellPrice(uint _dS) public view returns(uint) {
        return MathLib.sellIntegral(totalSupply(), _dS);
    }
 
    // function burnFrom(address account, uint256 amount) external override(ERC20Burnable) {
    //     burnFrom(account, amount);
    // }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function Buy(uint _dS) external payable returns(uint) {
        require(buyPrice(_dS) == msg.value, "Wrong value, Send the exact price");
        _mint(msg.sender, _dS);
        return(totalSupply());
    }

    function Sell(uint _dS) external returns(uint) {
        require(balanceOf(msg.sender) > 0, "You don't have any token to sell.");
        require(_dS <= balanceOf(msg.sender), "You don't have this amount of token");
        _burn(msg.sender, _dS);
        payable(msg.sender).transfer(sellPrice(_dS));
        return(totalSupply());
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
