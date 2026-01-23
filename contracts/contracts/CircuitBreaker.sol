// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CircuitBreaker is Ownable {
    uint256 public dailyLimit;
    uint256 public currentSpend;
    uint256 public lastResetTime;
    
    // Whitelisted addresses that can record spends (e.g. AgentWallets)
    mapping(address => bool) public isAuth;

    event LimitChanged(uint256 newLimit);
    event LimitReset();
    event SpendRecorded(address indexed spender, uint256 amount);

    constructor(uint256 _dailyLimit, address _owner) Ownable(_owner) {
        dailyLimit = _dailyLimit;
        lastResetTime = block.timestamp;
    }

    modifier onlyAuth() {
        require(isAuth[msg.sender] || msg.sender == owner(), "Not authorized");
        _;
    }

    function addAuth(address _caller) external onlyOwner {
        isAuth[_caller] = true;
    }

    function removeAuth(address _caller) external onlyOwner {
        isAuth[_caller] = false;
    }

    function checkLimit(uint256 amount) public view returns (bool) {
        if (block.timestamp > lastResetTime + 1 days) {
            return amount <= dailyLimit;
        }
        return (currentSpend + amount) <= dailyLimit;
    }

    function recordSpend(uint256 amount) external onlyAuth {
        if (block.timestamp > lastResetTime + 1 days) {
            currentSpend = 0;
            lastResetTime = block.timestamp;
            emit LimitReset();
        }
        require(currentSpend + amount <= dailyLimit, "Daily limit exceeded");
        currentSpend += amount;
        emit SpendRecorded(msg.sender, amount);
    }

    function setLimit(uint256 _newLimit) external onlyOwner {
        dailyLimit = _newLimit;
        emit LimitChanged(_newLimit);
    }
    
    function resetSpend() external onlyOwner {
        currentSpend = 0;
        lastResetTime = block.timestamp;
        emit LimitReset();
    }
}
