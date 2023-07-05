// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC20 } from "../lib/forge-std/src/interfaces/IERC20.sol";

contract BasicVault {
    
    // STATE VARS: 
    // token
    IERC20 public immutable funToken;

    // mapping to serve as balances registry
    mapping (address => uint) public balances;

    // events
    event Deposited (address indexed from, uint amount);
    event Withdrawn (address indexed to, uint amount);
    
    // constructor function
    constructor(IERC20 funToken_) {
        funToken = funToken_;
    }
    
    // deposit function
    function deposit (uint amount) external {
        balances[msg.sender] += amount;

        //external call
        bool success = funToken.transferFrom (msg.sender, address(this), amount);
        require (success, "Deposit failed!");
        
        //internal state update
        emit Deposited (msg.sender, amount);
    }
    
    // withdraw function 
    function withdraw (uint amount) external {
        balances[msg.sender] -= amount;

        //external call
        bool success = funToken.transfer (msg.sender, amount);
        require (success, "Withdrawal failed!");
        
        //internal state update
        emit Withdrawn (msg.sender, amount);
    }
}
