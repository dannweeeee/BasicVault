// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { FunToken } from "../src/FunToken.sol";

contract FunTokenWithFailedTransfers is FunToken {
    
    bool public transferFail = false;
    
    function setFailTransfers(bool state_) public {
        transferFail = state_;
    }

    function _transfer(address src, address dst, uint wad) internal override returns (bool) {
        if (transferFail){
            return false;
        }
        else {
            return super._transfer(src, dst, wad);
        }
    }
}