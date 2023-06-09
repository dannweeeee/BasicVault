// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/BasicVault.sol";
import "../test/FunTokenWithFailedTransfers.sol";

abstract contract StateZero is Test {
        
    BasicVault public vault;
    FunTokenWithFailedTransfers public fun;
    address user;

    event Deposited(address indexed from, uint amount);
    event Withdrawal(address indexed from, uint amount);

    function setUp() public virtual {
        fun = new FunTokenWithFailedTransfers();
        vault = new BasicVault(IERC20(address(fun)));

        user = address(1);
        vm.label(user, "user");
    }
}

contract StateZeroTest is StateZero {
    
    function testGetUserBalance() public {
        console2.log("Check User has zero tokens in vault");
        vm.prank(user);
        uint balance = vault.balances(user);
        assertTrue(balance == 0);
    }

    function testUserCannotDeposit(uint amount) public {
        console2.log("User cannot deposit without tokens");
        vm.assume(amount > 0);
        vm.prank(user);
        vm.expectRevert("ERC20: Insufficient approval");
        vault.deposit(amount);
    }
   
    function testUserMintApproveDeposit(uint amount) public {
        console2.log("User mints tokens and deposits into vault");
        vm.startPrank(user);
        vm.assume(amount > 0);
        fun.mint(user, amount);
        fun.approve(address(vault), amount);

        vm.expectEmit(true, false, false, true);
        emit Deposited(user, amount);
        vault.deposit(amount);

        assertTrue(fun.balanceOf(user) == 0);
        assertTrue(vault.balances(user) == amount);
        vm.stopPrank();
    }

}

abstract contract StateMinted is StateZero {
    uint userTokens;
    
    function setUp() public override virtual {
        super.setUp();
        
        // state transition: user mints 100 tokens
        userTokens = 100 * 10**18;
        vm.prank(user);
        fun.mint(user, userTokens);
    }
}

contract StateMintedTest is StateMinted {

    function testFuzzUserCannotWithdraw(uint amount) public {
        console2.log("User cannot withdraw with no balance");
        vm.assume(amount > 0 && amount < fun.balanceOf(user));
        vm.prank(user);
        vm.expectRevert(stdError.arithmeticError);
        vault.withdraw(amount);
    }

    function testDepositRevertsIfTransferFails() public {
        console2.log("Deposit transaction should revert if transfer fails");
        fun.setFailTransfers(true);
        
        vm.startPrank(user);
        fun.approve(address(vault), userTokens);
        vm.expectRevert("Deposit Failed!");
        vault.deposit(userTokens);
        vm.stopPrank();
    }

    function testDeposit() public {
        console2.log("User deposits into Vault");
        vm.startPrank(user);
        fun.approve(address(vault), userTokens);
        
        vm.expectEmit(true, false, false, true);
        emit Deposited(user, userTokens);
        vault.deposit(userTokens);
        
        assertTrue(vault.balances(user) == userTokens);
        assertTrue(fun.balanceOf(user) == 0);
        vm.stopPrank();
    }

}

abstract contract StateDeposited is StateMinted {
    
    function setUp() public override virtual {
        super.setUp();  
        vm.startPrank(user);
        fun.approve(address(vault), userTokens);
        vault.deposit(userTokens);
        vm.stopPrank();
    }
}

contract StateDepositedTest is StateDeposited {
    
    function testWithdrawRevertsIfTransferFails() public {
        console2.log("Withdraw transaction should revert if transfer fails");
        fun.setFailTransfers(true);
        vm.prank(user);
        vm.expectRevert("Withdrawal Failed!");
        vault.withdraw(userTokens);
    }

    function testUserCannotWithdrawExcessOfDeposit() public {
        console2.log("User cannot withdraw more than he has deposited");
        vm.prank(user);
        vm.expectRevert(stdError.arithmeticError);
        vault.withdraw(userTokens + 100*10**18);
    }

    function testUserWithdrawPartial() public {
        console2.log("User withdraws half of deposits from Vault");
        vm.prank(user);

        vm.expectEmit(true, false, false, true);
        emit Withdrawal(user, userTokens/2);
        vault.withdraw(userTokens/2);

        assertEq(vault.balances(user), userTokens/2);
        assertEq(fun.balanceOf(user), userTokens/2);
    }
 
    function testUserWithdrawAll() public {
        console2.log("User withdraws all deposits from Vault");
        vm.prank(user);

        vm.expectEmit(true, false, false, true);
        emit Withdrawal(user, userTokens);
        vault.withdraw(userTokens);

        assertEq(vault.balances(user), 0);
        assertEq(fun.balanceOf(user), userTokens);
    }
}