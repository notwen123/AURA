// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDCHandler is Ownable {
    IERC20 public usdc;

    event PaymentProcessed(address indexed payer, uint256 amount, string reason);

    constructor(address _usdc, address _owner) Ownable(_owner) {
        usdc = IERC20(_usdc);
    }

    // EIP-3009 / ERC-2612 Gasless Payment
    function payWithPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        string memory reason
    ) external {
        try IERC20Permit(address(usdc)).permit(owner, spender, value, deadline, v, r, s) {
            // Permit successful
        } catch {
            // If permit fails (maybe already permitted), we try transferFrom
        }
        
        require(usdc.transferFrom(owner, address(this), value), "Transfer failed");
        emit PaymentProcessed(owner, value, reason);
    }
    
    // Simple transfer for agents that have approved this contract
    function pay(uint256 amount, string memory reason) external {
        require(usdc.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit PaymentProcessed(msg.sender, amount, reason);
    }
}
