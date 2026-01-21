// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title CircuitBreaker
 * @dev Safety guardrails for agent spending
 */
contract CircuitBreaker is Ownable {
    
    IERC20 public usdcToken;
    
    // Global limits
    uint256 public perRequestLimit = 50e6; // $50
    uint256 public perMissionLimit = 500e6; // $500
    uint256 public maxRequestsPerMinute = 10;
    
    // Tracking per agent
    mapping(address => uint256) public lastRequestTimestamp;
    mapping(address => uint256) public requestCountInWindow;
    mapping(address => mapping(bytes32 => uint256)) public missionSpends;
    
    // Events
    event LimitEnforced(address indexed agent, uint256 requestedAmount, string reason);
    event SpendingRecorded(address indexed agent, uint256 amount, bytes32 missionId);
    event LimitsUpdated(uint256 newPerRequest, uint256 newPerMission);
    
    constructor(address _usdcToken) {
        usdcToken = IERC20(_usdcToken);
    }
    
    /**
     * @dev Check if operation is within limits
     */
    function checkLimit(
        address _agent,
        uint256 _amount,
        bytes32 _missionId
    ) external view returns (bool allowed, uint256 remainingBudget) {
        // Check per-request limit
        if (_amount > perRequestLimit) {
            return (false, 0);
        }
        
        // Check per-mission limit
        uint256 missionSpend = missionSpends[_agent][_missionId];
        if (missionSpend + _amount > perMissionLimit) {
            return (false, perMissionLimit - missionSpend);
        }
        
        // Check rate limit (requests per minute)
        uint256 timeSinceLastRequest = block.timestamp - lastRequestTimestamp[_agent];
        if (timeSinceLastRequest < 60) {
            if (requestCountInWindow[_agent] >= maxRequestsPerMinute) {
                return (false, 0);
            }
        }
        
        return (true, perRequestLimit);
    }
    
    /**
     * @dev Record spending
     */
    function recordSpend(
        address _agent,
        uint256 _amount,
        bytes32 _missionId
    ) external onlyOwner {
        (bool allowed, ) = this.checkLimit(_agent, _amount, _missionId);
        require(allowed, "Spending limit exceeded");
        
        // Update mission spending
        missionSpends[_agent][_missionId] += _amount;
        
        // Update rate limiting
        uint256 timeSinceLastRequest = block.timestamp - lastRequestTimestamp[_agent];
        if (timeSinceLastRequest < 60) {
            requestCountInWindow[_agent]++;
        } else {
            lastRequestTimestamp[_agent] = block.timestamp;
            requestCountInWindow[_agent] = 1;
        }
        
        emit SpendingRecorded(_agent, _amount, _missionId);
    }
    
    /**
     * @dev Reset mission spending
     */
    function resetMission(
        address _agent,
        bytes32 _missionId
    ) external onlyOwner {
        missionSpends[_agent][_missionId] = 0;
    }
    
    /**
     * @dev Update limits (admin only)
     */
    function updateLimits(
        uint256 _newPerRequest,
        uint256 _newPerMission,
        uint256 _newMaxRequestsPerMinute
    ) external onlyOwner {
        require(_newPerRequest > 0 && _newPerMission > 0, "Invalid limits");
        
        perRequestLimit = _newPerRequest;
        perMissionLimit = _newPerMission;
        maxRequestsPerMinute = _newMaxRequestsPerMinute;
        
        emit LimitsUpdated(_newPerRequest, _newPerMission);
    }
}
