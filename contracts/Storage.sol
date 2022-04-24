/**
 __  __     ______     ______     ______     __    
/\ \_\ \   /\  __ \   /\  ___\   /\  __ \   /\ \   
\ \  __ \  \ \  __ \  \ \___  \  \ \  __ \  \ \ \  
 \ \_\ \_\  \ \_\ \_\  \/\_____\  \ \_\ \_\  \ \_\ 
  \/_/\/_/   \/_/\/_/   \/_____/   \/_/\/_/   \/_/ 

 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./interface.sol";

contract Storage {
    mapping(address => EnumerableSetUpgradeable.UintSet) internal userBorrowIdMap;

    EnumerableSetUpgradeable.AddressSet internal supportNFT;

    // nftAddress => NFTSeries
    mapping(address => NFTSeries) public collectionMap;

    EnumerableSetUpgradeable.UintSet internal auctions;

    // requestId => Request
    mapping(bytes32 => Request) public requestMap;

    // borrowId => BorrowItem
    mapping(uint => BorrowItem) public borrowMap;

    mapping(uint => Auction) public auctionMap;
}
