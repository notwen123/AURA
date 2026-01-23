// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CircuitBreaker {
    uint256 public dailyLimit;
    uint256 public currentSpend;
    uint256 public lastResetTime;
    address public owner;

    constructor(uint256 _dailyLimit) {
        dailyLimit = _dailyLimit;
        owner = msg.sender;
        lastResetTime = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function checkLimit(uint256 amount) external {
        if (block.timestamp > lastResetTime + 1 days) {
            currentSpend = 0;
            lastResetTime = block.timestamp;
        }
        require(currentSpend + amount <= dailyLimit, "Daily limit exceeded");
        currentSpend += amount;
    }

    function setLimit(uint256 _newLimit) external onlyOwner {
        dailyLimit = _newLimit;
    }
}
