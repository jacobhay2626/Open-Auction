// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

error AuctionAlreadyEnded();
error NotHighEnoughBid(uint256 highestBid);
error AuctionNotYetEnded();
error AuctionEndAlreadyCalled();

contract SimpleAuction {
    // --------------------------------------------------------------
    // VARIABLES
    uint256 public auctionEndTime;
    address payable public beneficiary;

    uint256 public highestBid;
    address public highestBidder;

    mapping(address => uint256) pendingReturns;

    bool ended;

    // --------------------------------------------------------------
    // EVENTS
    event NewHighestBid(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    // --------------------------------------------------------------

    constructor(uint256 biddingTime, address payable beneficiaryAddress) {
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
    }

    function bid() external payable {
        if (block.timestamp > auctionEndTime) {
            revert AuctionAlreadyEnded();
        }
        if (msg.value <= highestBid) {
            revert NotHighEnoughBid(highestBid);
        }

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit NewHighestBid(msg.sender, msg.value);
    }

    function withdraw() external returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() external {
        if (block.timestamp < auctionEndTime) {
            revert AuctionNotYetEnded();
        }

        if (ended) {
            revert AuctionEndAlreadyCalled();
        }

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        beneficiary.transfer(highestBid);
    }
}
