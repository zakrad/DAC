// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IToken.sol";
import "./libraries/MathLib.sol";


contract MyToken is ERC20, ERC20Snapshot, Ownable, ERC20Permit, ERC20Votes, Pausable {

    uint256 internal initialSupply;
    uint256 internal eachTokenPrice;
    IToken private token;
    mapping(address => uint256) public ethBalance; 
    mapping(address => uint256) public tokenBalance; 
    mapping(address => uint256) public initialToken; 
    mapping(address => bool) public entered;
    mapping(address => bool) public claimed;
    bool public won;

    constructor(address mother) ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        token = IToken(mother);
        _mint(mother, token.getSupply(token.getCurrentId()));
    }
     


    function snapshot() public onlyOwner {
        _snapshot();
    }

    modifier hasEntered() {
        require(entered[msg.sender] == true, "You have to enter first");
    }

    modifier notClaimed() {
        require(claimed[msg.sender] == false, "You claimed before");
    }

    function enterMarket() external whenNotPaused returns(uint256) {
        require(entered[msg.sender] == false, "You have entered before");
        initialToken[msg.sender] = token.getBalance(msg.sender, token.getCurrentId());
        require(initialToken[msg.sender] > 0, "You have nothing in mother token");
        entered[msg.sender] = true;
        tokenBalance[msg.sender] = initialToken[msg.sender];
        return initialToken[msg.sender];
    }

    function transferFunds() external whenPaused onlyOwner {
        if(won) {payable(address(token)).transfer();}
    }

    function endMarket(bool state) onlyOwner returns(uint256) {
        uint256 realToken = totalSupply() - balanceOf(address);
        eachTokenPrice = address(this).balance / realToken;
        won = state;
        pause();
        return eachTokenPrice;
    }

    function exitMarket() external hasEntered whenPaused notClaimed returns(uint256) {
        claimed[msg.sender] == true;
        if(won) {
            if(ethBalance[msg.sender] > 0) {
                uint256 ethToPay = ethBalance[msg.sender];
                uint256 diff = initialToken[msg.sender] - tokenBalance[msg.sender];
                ethBalance[msg.sender] = 0;
                token.burnFrom(msg.sender, diff);
                payable(msg.sender).transfer(ethToPay);     
            } else {
                token.mint(msg.sender, balanceOf(msg.sender));           
            }
        } else {
            if(balanceOf(msg.sender) > 0) {               
                uint256 balance = balanceOf(msg.sender);
                burn(msg.sender, balance);
                payable(msg.sender, balance * eachTokenPrice);       
            }
        }
    }

    function buyPrice(uint _dS) public view returns(uint) {
        return MathLib.buyIntegral(totalSupply(), _dS);
    }

    function sellPrice(uint _dS) public view returns(uint) {
        return MathLib.sellIntegral(totalSupply(), _dS);
    }


    function Buy(uint _dS) external payable hasEntered whenNotPaused returns(uint) {
        require(buyPrice(_dS) == msg.value, "Wrong value, Send the exact price");
        if(initialToken[msg.sender] == 0){
            _mint(msg.sender, _dS);
            return(balanceOf(msg.sender));
        } else {
            if(balanceOf(msg.sender) == 0){
                uint diff = initialToken[msg.sender] - tokenBalance[msg.sender];
                if(_dS > diff ){
                    tokenBalance[msg.sender] += diff;
                    ethBalance[msg.sender] -= msg.value;
                    _mint(msg.sender, _dS - diff);
                    _mint(address(token), diff);
                    return(balanceOf(msg.sender) + tokenBalance[msg.sender]);
                } else {
                    tokenBalance[msg.sender] += diff;
                    ethBalance[msg.sender] -= msg.value;
                    _mint(address(token), diff);
                    return(tokenBalance[msg.sender]);
                }
            } else {
                _mint(msg.sender, _dS);
                return(balanceOf(msg.sender) + tokenBalance[msg.sender]);
            }
        }
    }

    function Sell(uint _dS) external hasEntered whenNotPaused returns(uint) {
        require(_dS <= balanceOf(msg.sender) + tokenBalance[msg.sender], "not enough token.");
        if (balanceOf(msg.sender) == 0){
            tokenBalance[msg.sender] -= _dS;
            uint sellAmount = sellPrice(balanceOf(_dS));
            _burn(address(token), _dS);
            ethBalance[msg.sender] += sellAmount;
            return(tokenBalance[msg.sender]);
        } else {
            if(_dS <= balanceOf(msg.sender)){
                uint sellAmount = sellPrice(_dS);
                _burn(msg.sender, _dS);
                payable(msg.sender).transfer(sellAmount);
                return(balanceOf(msg.sender) + tokenBalance[msg.sender]);
            } else {
                uint256 diff = _dS - balanceOf(msg.sender);
                tokenBalance[msg.sender] -= diff;
                uint sellAmount = sellPrice(balanceOf(msg.sender));
                uint diffAmount = sellPrice(diff);
                _burn(msg.sender, balanceOf(msg.sender));
                _burn(address(token), diff);
                ethBalance[msg.sender] += diffAmount;
                payable(msg.sender).transfer(sellAmount);
                return(tokenBalance[msg.sender]);
            }
        }
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
