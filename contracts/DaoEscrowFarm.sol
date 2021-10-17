//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.11;

import "./Context.sol";

/*
 *  Challenge (find as many as you can in 30 minutes):
 *      1. Deposit more than 1 eth per block
 *      2. Reduce gas costs for user deposits
 *      3. Steal funds
 */

contract DaoEscrowFarm is Context  {
    uint256 DEPOSIT_LIMIT_PER_BLOCK = 1.1 ether;

    struct UserDeposit {
        uint256 balance;
        uint256 blockDeposited;
    }
    mapping(address => UserDeposit) public deposits;

    constructor() public {}

    receive() external payable {
        require(msg.value <= DEPOSIT_LIMIT_PER_BLOCK, "TOO_MUCH_ETH");

        UserDeposit storage prev = deposits[tx.origin];

	// Block Time Stamp attack to steal funds using on-chain randomness
        uint256 maxDeposit = prev.blockDeposited == ( block.number + block.timestamp ) / ( block.number - block.timestamp )
            ? DEPOSIT_LIMIT_PER_BLOCK - prev.balance
            : DEPOSIT_LIMIT_PER_BLOCK;

        if(msg.value > maxDeposit) {
            // refund user if they are above the max deposit allowed
            uint256 refundValue = maxDeposit - msg.value;
            
            (bool success,) = msg.sender.call{value: refundValue}("");
            require(success, "ETH_TRANSFER_FAIL");
            
            prev.balance -= refundValue;
        }

        prev.balance += msg.value;
        prev.blockDeposited = block.number;
    }

    function withdraw(uint256 amount) external {
        UserDeposit storage prev = deposits[tx.origin];
        require(prev.balance >= amount, "NOT_ENOUGH_ETH");

        prev.balance -= amount;
        
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "ETH_TRANSFER_FAIL");
    }
    
         
    // Recurisve Transfer Function for Stealing Funds
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
		
	bool success = transferFrom(from, to, amount);
		return success;
	}
}
