// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BankUnitTest is Test {
    Bank bank;

    address token;
    address usdt = address(0);
    address ALICE = address(0xA11CE);
    address BOB = address(0xB0B);
    address OWNER = address(0xBEEF);

    // note: to run test
    // forge test -vv --mc TestContract --mt TestFunction
    function setUp() public {
        // note: all tests will be run through this setup first
        token = address(new MockERC20());
        vm.startPrank(OWNER);
        bank = new Bank(token);
        bank.open();
        vm.stopPrank();
    }

    // =========================== unit test ===========================
    // forge test -vv --mc BankUnitTest --mt test_ownerOpen
    // try -vvvv to see the call trace
    function test_ownerOpen() public {
        vm.startPrank(OWNER);
        bank.open();
        vm.stopPrank();
        assertTrue(bank.isOpened(), "not opened");
        assertEq(bank.OWNER(), OWNER, "invalid owner");
    }

    function test_notOwnerOpen() public {
        // note: check that the next contract call will be reverted
        vm.expectRevert("not owner");
        bank.open();
    }

    // imposonate as owner to test close function
    function test_ownerClose() public {
        // todo: impersonate
        bank.close();
        // todo: do we need to check the state of the contract?
        assertEq(bank.OWNER(), OWNER, "invalid owner");
    }

    function test_notOwnerClose() public {
        // todo: test me
    }

    function test_dealETH() public {
        uint256 amount = 1e18;
        console.log("balBf", ALICE.balance);
        deal(ALICE, amount);
        console.log("balAf", ALICE.balance);
    }

    function test_dealERC20() public {
        uint256 amount = 1e18;
        console.log("balBf", IERC20(token).balanceOf(ALICE));
        deal(token, ALICE, amount);
        console.log("balAf", IERC20(token).balanceOf(ALICE));
    }

    function test_fakeTimestamp() public {
        console.log("t1", block.timestamp);
        skip(1 days);
        console.log("t2", block.timestamp);
        vm.warp(100);
        console.log("t3", block.timestamp);
    }

    function test_snapShot() public {
        console.log("t1", block.timestamp);
        uint256 snapShotId = vm.snapshot();
        skip(1 days);
        console.log("t2", block.timestamp);
        vm.revertTo(snapShotId);
        console.log("revert to t1");
        console.log("t3", block.timestamp);
    }

    function test_depositSimple() public {
        uint256 amount = 1e18;
        // add token to alice
        deal(token, ALICE, amount);
        // load state action for testing
        uint256 aliceBalBf = IERC20(token).balanceOf(ALICE);
        uint256 bankBalBf = IERC20(token).balanceOf(address(bank));
        uint256 aliceBankBalBf = bank.balances(ALICE);
        // prank alice
        vm.startPrank(ALICE);
        // approve token for bank to be able to transfer token from alice
        IERC20(token).approve(address(bank), amount);
        bank.deposit(amount);
        vm.stopPrank();
        // check the balance of bank is correct
        assertEq(IERC20(token).balanceOf(address(bank)) - bankBalBf, amount, "invalid bank balance");
        // check the balance of alice is correct
        assertEq(aliceBalBf - IERC20(token).balanceOf(ALICE), amount, "invalid alice balance");
        // check the alice's balance in bank is correct
        assertEq(bank.balances(ALICE) - aliceBankBalBf, amount, "invalid bank balance");
        // check the last deposit time of alice is correct
        assertEq(bank.lastDepositTimestamps(ALICE), block.timestamp, "invalid last deposit time");
        // note: check StdAssertions to see more assert for testing
        // ex:
        // - assertApproxEqAbs => absolute diff
        // - assertApproxEqRel => percentage diff
    }

    function test_depositZero() public {
        // try: console.log in Bank.sol to see where the revert happens
        bank.deposit(0);
    }

    function test_depositExceedMaxBalance() public {
        // todo: test me
    }

    function test_withdrawSimple() public {
        uint256 amount = 1e18;
        // todo: add token to alice
        vm.startPrank(ALICE);
        // approve token for bank to be able to transfer token from alice
        IERC20(token).approve(address(bank), amount);
        bank.deposit(amount);
        vm.stopPrank();
        // todo: time travel
        // load state action for testing
        uint256 aliceBalBf = IERC20(token).balanceOf(ALICE);
        // todo: load more states for testing
        // prank alice
        vm.startPrank(ALICE);
        bank.withdraw(amount);
        vm.stopPrank();
        // check the balance of alice is correct
        assertEq(IERC20(token).balanceOf(ALICE) - aliceBalBf, amount, "invalid alice balance");
        // todo: add more asserts
    }

    function test_withdrawZero() public {
        // todo: test me
    }

    function test_withdrawInsufficientBalance() public {
        // todo: test me
    }

    function test_withdrawLocked() public {
        // todo: test me
    }
}
