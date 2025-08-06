// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TimeLockedGiftVault {
    struct Gift {
        uint256 amount;
        uint256 unlockTimestamp;
        bool claimed;
    }

    // Mapping of recipient => array of gifts
    mapping(address => Gift[]) public gifts;

    event GiftCreated(address indexed from, address indexed to, uint256 amount, uint256 unlockTimestamp);
    event GiftClaimed(address indexed to, uint256 amount);

    // Create a time-locked gift for someone
    function createGift(address _recipient, uint256 _unlockTimestamp) external payable {
        require(msg.value > 0, "Gift amount must be greater than 0");
        require(_recipient != address(0), "Invalid recipient address");
        require(_unlockTimestamp > block.timestamp, "Unlock time must be in the future");

        gifts[_recipient].push(Gift({
            amount: msg.value,
            unlockTimestamp: _unlockTimestamp,
            claimed: false
        }));

        emit GiftCreated(msg.sender, _recipient, msg.value, _unlockTimestamp);
    }

    // Claim all unlocked gifts
    function claimGifts() external {
        Gift[] storage userGifts = gifts[msg.sender];
        uint256 totalClaimed = 0;

        for (uint256 i = 0; i < userGifts.length; i++) {
            Gift storage g = userGifts[i];
            if (!g.claimed && block.timestamp >= g.unlockTimestamp) {
                totalClaimed += g.amount;
                g.claimed = true;
            }
        }

        require(totalClaimed > 0, "No unlocked gifts available to claim");
        payable(msg.sender).transfer(totalClaimed);

        emit GiftClaimed(msg.sender, totalClaimed);
    }

    // View function to get pending/unclaimed gifts for a user
    function getPendingGifts(address _recipient) external view returns (Gift[] memory) {
        return gifts[_recipient];
    }
}
