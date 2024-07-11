// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract Bank {
    uint256 public constant LOCK_PERIOD = 1 days;
    address public immutable OWNER;
    address public asset;
    bool public isOpened;
    uint256 public maxBalance;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastDepositTimestaps;

    constructor(address asset_) {
        OWNER = msg.sender;
        asset = asset_;
        maxBalance = type(uint128).max;
    }

    modifier onlyOwner() {
        require(msg.sender == OWNER, "not owner");
        _;
    }

    modifier onlyOpened() {
        require(isOpened, "not opened");
        _;
    }

    function open() public onlyOwner {
        isOpened = true;
    }

    function close() public onlyOwner {
        isOpened = false;
    }

    function deposit(uint256 amount) public onlyOpened {
        // check
        // console.log("test");
        require(amount > 0);
        // console.log("test1");
        require(IERC20(asset).balanceOf(address(this)) + amount <= maxBalance, "exceed max balance");
        // console.log("test2");
        // update
        balances[msg.sender] += amount;
        lastDepositTimestaps[msg.sender] = block.timestamp;
        // interact
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public onlyOpened {
        // check
        require(amount > 0, "zero withdraw");
        require(balances[msg.sender] >= amount, "insufficient balance");
        require(block.timestamp >= lastDepositTimestaps[msg.sender] + LOCK_PERIOD, "locked");
        // update
        balances[msg.sender] -= amount;
        // interact
        IERC20(asset).transfer(msg.sender, amount);
    }
}
