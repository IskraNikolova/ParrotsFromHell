// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./access/Ownable.sol";

/**
 * Contract for ticket sales
 */
contract TicketSale is Ownable {
    // The current number of available tickets
    uint8 public ticketCount = 10;

    // The price of a single ticket in ETH
    uint256 public ticketPrice = 50 ether;

    // An array of addresses representing the contract administrators
    address[] private admins;

    // Map of addresses representing the ticket buyers
    mapping(address => uint256) public buyers;

    // A flag to indicate if the contract is currently paused
    bool public paused = false;

    /**
     * Event emitted when a ticket is bought
     * @param buyer The address of the buyer
     */
    event TicketBought(address indexed buyer);

    /**
     * Event emitted when the contract is paused
     */
    event ContractPaused();

    /**
     * Event emitted when the contract is resumed
     */
    event ContractResumed();

    /**
     * Event emitted when the ticket count is changed
     * @param newCount The new ticket count
     */
    event TicketCountChanged(uint8 newCount);

    /**
     * Constructor to initialize the contract with administrators
     * @param _admins An array of addresses representing the contract administrators
     */
    constructor(address[] memory _admins) {
        admins = _admins;
    }

    /**
     * Function to allow a buyer to purchase a ticket
     */
    function buyTicket() public payable {
        // Check if the contract is currently paused
        require(!paused, "The contract is currently paused");

        // Check if tickets are still available
        require(ticketCount > 0, "Tickets are sold out");

        // Check if the buyer has provided enough ETH
        require(msg.value >= ticketPrice, "Not enough ETH provided");

        // Decrement the ticket count
        ticketCount--;

        // Add the buyer to the buyers map
        buyers[msg.sender]++;

        // Calculate the transfer amount for each administrator
        uint256 transferAmount = (msg.value - ticketPrice) / uint256(admins.length);

        // Transfer the calculated amount to each administrator
        for (uint256 i = 0; i < admins.length; i++) {
            payable(admins[i]).transfer(transferAmount);
        }

        // Emit the TicketBought event
        emit TicketBought(_msgSender());
    }

    /**
     * Function to allow the owner to pause the contract
     */

    function pause(bool state_)
        public onlyOwner {
        paused = state_;
    }

    function setTicketCount(uint8 count)
        public onlyOwner{
        ticketCount += count;
        emit TicketCountChanged(ticketCount);
    }
}
