// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library MathLib{

    function buyIntegral(uint _totalSupply, uint _dS) internal pure returns(uint){
        uint dF = 1000 * (sqrt((_totalSupply+_dS)**2+10**6)-sqrt(_totalSupply**2+10**6));
        return dF;
    }

    function sellIntegral(uint _totalSupply, uint _dS) internal pure returns(uint){
        uint dF = 1000 * (sqrt(_totalSupply**2+10**6)-sqrt((_totalSupply-_dS)**2+10**6));
        return dF;
    }

    function inverseIntegral(uint _totalSupply, uint _dF) internal pure returns(uint){
        uint dS = (sqrt(((10**6)*(_totalSupply**2))+((_dF)**2)+(2000*_dF*sqrt(_totalSupply**2+10**6)))-(1000*_totalSupply))/1000;
        return dS;
    }

    function sqrt(uint y) private pure returns (uint z) {
    if (y > 3) {
        z = y;
        uint x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    } else if (y != 0) {
        z = 1;
    }
  }
}