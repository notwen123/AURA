// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CircuitBreaker.sol";

contract AgentWallet is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    CircuitBreaker public circuitBreaker;
    
    // Session Keys: address => timestamp expiry
    mapping(address => uint256) public sessionKeys;

    event Execution(address indexed target, uint256 value, bytes data);
    event SessionKeyAdded(address indexed key, uint256 expiry);
    event SessionKeyRevoked(address indexed key);

    constructor(address _owner, address _circuitBreaker) Ownable(_owner) {
        circuitBreaker = CircuitBreaker(_circuitBreaker);
    }

    modifier onlyAuth() {
        require(msg.sender == owner() || (sessionKeys[msg.sender] > block.timestamp), "Not authorized or session expired");
        _;
    }

    function addSessionKey(address _key, uint256 _validity) external onlyOwner {
        sessionKeys[_key] = block.timestamp + _validity;
        emit SessionKeyAdded(_key, block.timestamp + _validity);
    }

    function revokeSessionKey(address _key) external onlyOwner {
        delete sessionKeys[_key];
        emit SessionKeyRevoked(_key);
    }

    function execute(address target, uint256 value, bytes calldata data) external onlyAuth {
        // Enforce circuit breaker limits if not owner (agents are restricted)
        if (msg.sender != owner()) {
            require(circuitBreaker.checkLimit(value), "Circuit Breaker: Limit exceeded");
            circuitBreaker.recordSpend(value);
        }

        (bool success, ) = target.call{value: value}(data);
        require(success, "Execution failed");
        emit Execution(target, value, data);
    }

    function executeBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas) external onlyAuth {
        require(targets.length == values.length && values.length == datas.length, "Length mismatch");

        uint256 totalValue = 0;
        for(uint256 i = 0; i < values.length; i++) {
            totalValue += values[i];
        }

        if (msg.sender != owner()) {
            require(circuitBreaker.checkLimit(totalValue), "Circuit Breaker: Batch limit exceeded");
            circuitBreaker.recordSpend(totalValue);
        }

        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, ) = targets[i].call{value: values[i]}(datas[i]);
            require(success, "Batch Execution failed at index");
            emit Execution(targets[i], values[i], datas[i]);
        }
    }

    receive() external payable {}
}
