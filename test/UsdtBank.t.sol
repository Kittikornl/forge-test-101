// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";
import {SafeBank} from "../src/SafeBank.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UsdtBankTest is Test {
    using SafeERC20 for IERC20;

    // NOTE: usdt has bad implementation so we need to use SafeERC20 to avoid revert
    // Bank bank;
    SafeBank bank;

    address token;
    address usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address ALICE = address(0xA11CE);
    address BOB = address(0xB0B);
    address OWNER = address(0xBEEF);

    function setUp() public {
        token = usdt;
        vm.startPrank(OWNER);
        // bank = new Bank(token);
        bank = new SafeBank(token);
        bank.open();
        vm.stopPrank();
    }

    // =========================== forked test ===========================
    // note: to reduce time of test
    // find rpc from https://chainlist.org/ and use it to fork chain
    // - 1. run test in another terminal: forge test -vv --mc UsdtBankTest --mt testFunction --fork-url https://rpc.ankr.com/eth
    function test_depositSimple() public {
        uint256 amount = 100 * 1e6;
        // add token to alice
        // note: deal will edit the storage of token contract
        deal(token, ALICE, amount);
        // load state for testing
        uint256 aliceBalBf = IERC20(token).balanceOf(ALICE);
        uint256 bankBalBf = IERC20(token).balanceOf(address(bank));
        uint256 aliceBankBalBf = bank.balances(ALICE);
        // prank alice
        vm.startPrank(ALICE);
        // approve token for bank to be able to transfer token from alice
        IERC20(token).forceApprove(address(bank), amount);
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
    }

    // =========================== fuzz test ===========================
    function testFuzz_deposit(uint256 amount) public {
        // note: using amount to test might be failed for some edge cases
        // todo: uncomment the line below to test
        // amount = bound(amount, 1, bank.maxBalance() - IERC20(token).balanceOf(address(bank)));
        deal(token, ALICE, amount);
        // load state for testing
        uint256 aliceBalBf = IERC20(token).balanceOf(ALICE);
        uint256 bankBalBf = IERC20(token).balanceOf(address(bank));
        uint256 aliceBankBalBf = bank.balances(ALICE);
        // prank alice
        vm.startPrank(ALICE);
        // approve token for bank to be able to transfer token from alice
        IERC20(token).forceApprove(address(bank), amount);
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
    }

    function test_fuzzWithdraw(uint256 amount) public {
        // todo: test me
    }

    // =========================== senario test ===========================
    // note: senario test also have advanced testing
    // read more: https://book.getfoundry.sh/forge/invariant-testing
    function test_twoUserDeposit() public {
        // alice deposit
        uint256 aliceAmount = 100 * 1e6;
        deal(token, ALICE, aliceAmount);
        // prank alice
        vm.startPrank(ALICE);
        // approve token for bank to be able to transfer token from alice
        IERC20(token).forceApprove(address(bank), aliceAmount);
        bank.deposit(aliceAmount);
        vm.stopPrank();
        // load state for testing
        uint256 aliceBalBf = IERC20(token).balanceOf(ALICE);
        uint256 bankBalBf = IERC20(token).balanceOf(address(bank));
        uint256 aliceBankBalBf = bank.balances(ALICE);
        uint256 bobBankBalBf = bank.balances(BOB);
        uint256 aliceLastDepositTime = bank.lastDepositTimestamps(ALICE);
        // bob deposit
        uint256 bobAmount = 2 * 100 * 1e6;
        deal(token, BOB, bobAmount);
        uint256 bobBalBf = IERC20(token).balanceOf(BOB);
        // prank bob
        vm.startPrank(BOB);
        // approve token for bank to be able to transfer token from bob
        IERC20(token).forceApprove(address(bank), bobAmount);
        bank.deposit(bobAmount);
        vm.stopPrank();
        // check the balance of bank is correct
        assertEq(IERC20(token).balanceOf(address(bank)) - bankBalBf, bobAmount, "invalid bank balance");
        // check the balance of bob is correct
        assertEq(bobBalBf - IERC20(token).balanceOf(BOB), bobAmount, "invalid bob balance");
        // check the bob's balance in bank is correct
        assertEq(bank.balances(BOB) - bobBankBalBf, bobAmount, "invalid bank balance");
        // check the last deposit time of bob is correct
        assertEq(bank.lastDepositTimestamps(BOB), block.timestamp, "invalid last deposit time");
        // check the balance of alice is not changed
        assertEq(aliceBalBf - IERC20(token).balanceOf(ALICE), 0, "invalid alice balance");
        // check the alice's balance in bank is not changed
        assertEq(bank.balances(ALICE) - aliceBankBalBf, 0, "invalid bank balance");
        // check the last deposit time of alice is not changed
        assertEq(bank.lastDepositTimestamps(ALICE), aliceLastDepositTime, "invalid last deposit time");
    }

    function test_twoUserDepositAliceWithdraw() public {
        // todo: test me
    }

    // =========================== related known expliot test ===========================
    // note: this is plus
    // if we implement some smart contract that similar to other project which has known exploit
    // we can test it to make sure that our contract is not vulnerable
}
