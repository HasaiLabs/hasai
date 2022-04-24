/**
 __  __     ______     ______     ______     __    
/\ \_\ \   /\  __ \   /\  ___\   /\  __ \   /\ \   
\ \  __ \  \ \  __ \  \ \___  \  \ \  __ \  \ \ \  
 \ \_\ \_\  \ \_\ \_\  \/\_____\  \ \_\ \_\  \ \_\ 
  \/_/\/_/   \/_/\/_/   \/_____/   \/_/\/_/   \/_/ 

 */
 
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Configuration {
    bytes32 constant public MANAGE_ROLE = keccak256("MANAGE_ROLE");

    uint public constant BORROW_RATE_BASE = 10000;

    uint public constant APR_BASE = 10000;

    address internal priceOracle;

    uint public MIN_BORROW_TIME;

    address public WETH;
}
