// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AgentWallet {
    address public owner;
    
    event Execution(address indexed target, uint256 value, bytes data);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function execute(address target, uint256 value, bytes calldata data) external onlyOwner {
        (bool success, ) = target.call{value: value}(data);
        require(success, "Execution failed");
        emit Execution(target, value, data);
    }

    receive() external payable {}
}
