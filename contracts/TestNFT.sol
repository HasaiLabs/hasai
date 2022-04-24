/**
 __  __     ______     ______     ______     __    
/\ \_\ \   /\  __ \   /\  ___\   /\  __ \   /\ \   
\ \  __ \  \ \  __ \  \ \___  \  \ \  __ \  \ \ \  
 \ \_\ \_\  \ \_\ \_\  \/\_____\  \ \_\ \_\  \ \_\ 
  \/_/\/_/   \/_/\/_/   \/_____/   \/_/\/_/   \/_/ 

 */

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestNFT is ERC721, ERC721Holder {

    event NFTReceived(
        address indexed operator,
        address indexed from,
        uint256 indexed tokenId,
        bytes data
    );

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721Holder) returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function mint(address account, uint tokenId) public {
        super._mint(account, tokenId);
    }

    function _baseURI() internal view override returns(string memory) {
        return "https://ikzttp.mypinata.cloud/ipfs/QmQFkLSQysj94s5GvTHPyzTxrawwtjgiiYS2TBLgrvw8CW/";
    }
}
