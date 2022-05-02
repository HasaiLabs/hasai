/**
 __  __     ______     ______     ______     __    
/\ \_\ \   /\  __ \   /\  ___\   /\  __ \   /\ \   
\ \  __ \  \ \  __ \  \ \___  \  \ \  __ \  \ \ \  
 \ \_\ \_\  \ \_\ \_\  \/\_____\  \ \_\ \_\  \ \_\ 
  \/_/\/_/   \/_/\/_/   \/_____/   \/_/\/_/   \/_/ 

 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}

interface IPriceOracle {
    function requestNFTPrice(
        address _nft,
        address _callbackAddr,
        bytes4 _callbackFn
    ) external returns(bytes32);
}

interface IPunk {
    function transferPunk(address to, uint punkIndex) external;
}

enum Status { BORROW, REPAY, LIQUIDATE }

struct BorrowItem {
    address nft;
    address user;
    uint id;
    uint startTime;
    uint price;
    uint borrowId;
    uint liquidateTime;
    Status status;
}

struct NFTSeries {
    uint apr;
    uint borrowRate;
    string slug;
    uint period;
    string name;
}

struct Request {
    address user;
    address nft;
    uint id;
}

struct Auction {
    // ID for the Noun (ERC721 token ID)
    uint256 borrowId;
    // The current highest bid amount
    uint256 amount;
    // The time that the auction started
    uint256 startTime;
    // The time that the auction is scheduled to end
    uint256 endTime;
    // The address of the current highest bid
    address payable bidder;
    // Whether or not the auction has been settled
    bool settled;
}
