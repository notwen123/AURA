// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title AgentWallet
 * @dev Account Abstraction wallet for autonomous agents with Session Keys
 */
contract AgentWallet is Ownable, ReentrancyGuard {
    
    address public agent;
    address public sessionKey;
    IERC20 public usdcToken;
    
    // Policy parameters
    uint256 public maxSpendPerRequest = 50e6; // $50 in USDC (6 decimals)
    uint256 public maxSpendPerMission = 500e6; // $500 in USDC
    uint256 public dailySpendLimit = 1000e6; // $1000 in USDC
    
    // Tracking
    uint256 public totalSpentToday;
    uint256 public lastResetTime;
    mapping(bytes32 => uint256) public missionSpends;
    
    event SessionKeyAdded(address indexed sessionKey, uint256 expirationTime);
    event BatchExecuted(bytes32 indexed batchId, uint256 totalCost, bool success);
    event SpendingLimitEnforced(address indexed caller, uint256 requestedAmount);
    event DailyLimitReset(uint256 timestamp);
    
    constructor(address _agent, address _usdcToken) {
        agent = _agent;
        usdcToken = IERC20(_usdcToken);
        lastResetTime = block.timestamp;
    }
    
    /**
     * @dev Add session key for autonomous execution
     */
    function addSessionKey(
        address _sessionKey,
        uint256 _expirationTime
    ) external onlyOwner {
        require(_sessionKey != address(0), "Invalid session key");
        require(_expirationTime > block.timestamp, "Invalid expiration time");
        
        sessionKey = _sessionKey;
        emit SessionKeyAdded(_sessionKey, _expirationTime);
    }
    
    /**
     * @dev Check if spending is within limits
     */
    function checkSpendingLimit(
        uint256 _amount,
        bytes32 _missionId
    ) external view returns (bool allowed, uint256 remainingBudget) {
        _resetDailyLimitIfNeeded();
        
        // Check per-request limit
        if (_amount > maxSpendPerRequest) {
            return (false, 0);
        }
        
        // Check daily limit
        if (totalSpentToday + _amount > dailySpendLimit) {
            return (false, dailySpendLimit - totalSpentToday);
        }
        
        // Check per-mission limit
        if (missionSpends[_missionId] + _amount > maxSpendPerMission) {
            return (false, maxSpendPerMission - missionSpends[_missionId]);
        }
        
        return (true, maxSpendPerRequest);
    }
    
    /**
     * @dev Record spending
     */
    function recordSpend(
        uint256 _amount,
        bytes32 _missionId
    ) external onlyOwner {
        _resetDailyLimitIfNeeded();
        
        require(_amount <= maxSpendPerRequest, "Per-request limit exceeded");
        require(totalSpentToday + _amount <= dailySpendLimit, "Daily limit exceeded");
        require(missionSpends[_missionId] + _amount <= maxSpendPerMission, "Mission limit exceeded");
        
        totalSpentToday += _amount;
        missionSpends[_missionId] += _amount;
    }
    
    /**
     * @dev Execute batch of operations
     */
    function executeBatch(
        address[] calldata targets,
        bytes[] calldata data,
        uint256[] calldata values,
        bytes32 _batchId,
        bytes32 _missionId
    ) external payable nonReentrant returns (bytes[] memory) {
        require(msg.sender == sessionKey || msg.sender == owner(), "Unauthorized");
        require(targets.length == data.length && targets.length == values.length, "Array length mismatch");
        
        bytes[] memory results = new bytes[](targets.length);
        uint256 totalValue = 0;
        
        for (uint256 i = 0; i < targets.length; i++) {
            totalValue += values[i];
        }
        
        // Check spending limits
        (bool allowed, ) = this.checkSpendingLimit(totalValue, _missionId);
        require(allowed, "Spending limit exceeded");
        
        // Record spending
        this.recordSpend(totalValue, _missionId);
        
        // Execute all operations
        bool success = true;
        for (uint256 i = 0; i < targets.length; i++) {
            (bool callSuccess, bytes memory callResult) = targets[i].call{value: values[i]}(data[i]);
            results[i] = callResult;
            if (!callSuccess) {
                success = false;
            }
        }
        
        emit BatchExecuted(_batchId, totalValue, success);
        return results;
    }
    
    /**
     * @dev Reset daily limit if needed
     */
    function _resetDailyLimitIfNeeded() internal {
        if (block.timestamp >= lastResetTime + 1 days) {
            totalSpentToday = 0;
            lastResetTime = block.timestamp;
            emit DailyLimitReset(block.timestamp);
        }
    }
    
    /**
     * @dev Withdraw USDC tokens
     */
    function withdraw(uint256 _amount) external onlyOwner {
        require(usdcToken.balanceOf(address(this)) >= _amount, "Insufficient balance");
        require(usdcToken.transfer(msg.sender, _amount), "Transfer failed");
    }
    
    /**
     * @dev Receive ETH
     */
    receive() external payable {}
}
