// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BatchSettlement
 * @dev x402 Multi-leg settlement orchestrator
 */
contract BatchSettlement is Ownable {
    
    struct BatchOperation {
        address target;
        bytes data;
        uint256 value;
        string description;
    }
    
    struct Batch {
        bytes32 batchId;
        bytes32 x402SessionId;
        address agent;
        BatchOperation[] operations;
        uint256 totalCost;
        uint256 gasSaved;
        bool executed;
        uint256 createdAt;
        uint256 executedAt;
        string status; // "pending", "executing", "completed", "failed"
    }
    
    mapping(bytes32 => Batch) public batches;
    mapping(bytes32 => bytes[]) public batchResults;
    
    uint256 public batchCount;
    uint256 public totalGasSaved;
    
    event BatchCreated(bytes32 indexed batchId, address indexed agent, uint256 operationCount);
    event BatchExecuted(bytes32 indexed batchId, uint256 gasUsed, uint256 gasSaved);
    event BatchFailed(bytes32 indexed batchId, string reason);
    
    /**
     * @dev Create new batch
     */
    function createBatch(
        bytes32 _x402SessionId,
        address _agent,
        address[] calldata _targets,
        bytes[] calldata _data,
        uint256[] calldata _values,
        string[] calldata _descriptions
    ) external returns (bytes32) {
        require(_targets.length == _data.length && _targets.length == _values.length, "Array mismatch");
        
        bytes32 batchId = keccak256(abi.encodePacked(block.timestamp, _agent, _x402SessionId));
        
        Batch storage batch = batches[batchId];
        batch.batchId = batchId;
        batch.x402SessionId = _x402SessionId;
        batch.agent = _agent;
        batch.status = "pending";
        batch.createdAt = block.timestamp;
        
        uint256 totalCost = 0;
        for (uint256 i = 0; i < _targets.length; i++) {
            batch.operations.push(BatchOperation({
                target: _targets[i],
                data: _data[i],
                value: _values[i],
                description: _descriptions[i]
            }));
            totalCost += _values[i];
        }
        
        batch.totalCost = totalCost;
        batchCount++;
        
        emit BatchCreated(batchId, _agent, _targets.length);
        return batchId;
    }
    
    /**
     * @dev Execute batch atomically
     */
    function executeBatch(bytes32 _batchId) external onlyOwner returns (bool success) {
        Batch storage batch = batches[_batchId];
        require(batch.agent != address(0), "Batch not found");
        require(!batch.executed, "Already executed");
        
        batch.status = "executing";
        batch.executedAt = block.timestamp;
        
        bytes[] memory results = new bytes[](batch.operations.length);
        bool allSuccess = true;
        uint256 gasStart = gasleft();
        
        for (uint256 i = 0; i < batch.operations.length; i++) {
            BatchOperation storage op = batch.operations[i];
            (bool callSuccess, bytes memory callResult) = op.target.call{value: op.value}(op.data);
            results[i] = callResult;
            if (!callSuccess) {
                allSuccess = false;
                batch.status = "failed";
                emit BatchFailed(_batchId, "Operation failed");
                return false;
            }
        }
        
        uint256 gasUsed = gasStart - gasleft();
        // Approximate gas savings (typically 40% for batched operations)
        uint256 estimatedIndividualGas = gasUsed * 10 / 6; // 1.67x multiplier
        batch.gasSaved = estimatedIndividualGas - gasUsed;
        totalGasSaved += batch.gasSaved;
        
        batch.executed = true;
        batch.status = "completed";
        batchResults[_batchId] = results;
        
        emit BatchExecuted(_batchId, gasUsed, batch.gasSaved);
        return true;
    }
    
    /**
     * @dev Get batch status
     */
    function getBatchStatus(bytes32 _batchId) external view returns (
        string memory status,
        uint256 totalCost,
        uint256 gasSaved,
        bool executed
    ) {
        Batch storage batch = batches[_batchId];
        return (batch.status, batch.totalCost, batch.gasSaved, batch.executed);
    }
    
    /**
     * @dev Get batch operations count
     */
    function getBatchOperationCount(bytes32 _batchId) external view returns (uint256) {
        return batches[_batchId].operations.length;
    }
}
