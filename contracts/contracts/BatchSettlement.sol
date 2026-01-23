// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AgentWallet.sol";

contract BatchSettlement is Ownable {
    
    struct Settlement {
        address target;
        uint256 value;
        bytes data;
    }

    event BatchExecuted(address indexed agent, uint256 count);

    constructor(address _owner) Ownable(_owner) {}

    // Execute multi-leg settlement for an agent
    function executeBatchSettlement(
        address payable agentWallet,
        Settlement[] calldata settlements
    ) external onlyOwner {
        AgentWallet wallet = AgentWallet(agentWallet);
        
        // Prepare arrays for batch execution
        address[] memory targets = new address[](settlements.length);
        uint256[] memory values = new uint256[](settlements.length);
        bytes[] memory datas = new bytes[](settlements.length);

        for (uint256 i = 0; i < settlements.length; i++) {
            targets[i] = settlements[i].target;
            values[i] = settlements[i].value;
            datas[i] = settlements[i].data;
        }

        // Execute via AgentWallet (this contract must be authenticated or owner on the AgentWallet)
        // OR the caller must be authorized on the AgentWallet.
        // For this design, we assume the BatchSettlement contract is just a helper, 
        // and the ACTUAL caller (Orchestrator EOA) has session key access on the AgentWallet.
        
        // However, if we want this contract to bundle, it needs to call executeBatch.
        // But executeBatch checks msg.sender. So THIS contract needs to be auth'd.
        // Alternative: The orchestrator calls executeBatch DIRECTLY on AgentWallet.
        
        // IF we use this contract as a macro-orchestrator:
        wallet.executeBatch(targets, values, datas);
        
        emit BatchExecuted(agentWallet, settlements.length);
    }
}
