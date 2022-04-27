[![License: MIT](https://img.shields.io/badge/License-MIT-blue)](https://en.wikipedia.org/wiki/MIT_License)


```
 __  __     ______     ______     ______     __    
/\ \_\ \   /\  __ \   /\  ___\   /\  __ \   /\ \   
\ \  __ \  \ \  __ \  \ \___  \  \ \  __ \  \ \ \  
 \ \_\ \_\  \ \_\ \_\  \/\_____\  \ \_\ \_\  \ \_\ 
  \/_/\/_/   \/_/\/_/   \/_____/   \/_/\/_/   \/_/ 
                                                   
```

# what is Hasai

The first decentralized fixed-rate NFT lending protocol.

#### work flow

- user deposit nft(should be in our support list) to Hasai to get eth, once we get the NFT price through our self Oracle, we will get the nft from user and send ETH to user account.

- user can repay NFT anytime just need in valid borrow period. once user repay the nft, Hasai will send the nft to user account. if borrow-relationship is expired, everyone can liquidate the expired nft to start bid. bid period is 24 hours, each bid will increase bid period 1 hour. after bid end, the winner can claim the nft. if no one create a bid for the nft, we can withdraw the nft to sold


#### more

- each nft series has different borrow rate, period and apr.
- we will provide start liquidity
