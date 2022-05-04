/**
 __  __     ______     ______     ______     __    
/\ \_\ \   /\  __ \   /\  ___\   /\  __ \   /\ \   
\ \  __ \  \ \  __ \  \ \___  \  \ \  __ \  \ \ \  
 \ \_\ \_\  \ \_\ \_\  \/\_____\  \ \_\ \_\  \ \_\ 
  \/_/\/_/   \/_/\/_/   \/_____/   \/_/\/_/   \/_/ 

 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./Configuration.sol";
import "./Storage.sol";
import "./interface.sol";

contract Hasai is
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable,
    Configuration,
    Storage
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _borrowId;

    modifier onlyManager() {
        require(hasRole(MANAGE_ROLE, _msgSender()), "only manager");
        _;
    }

    modifier onlyPriceOracle() {
        require(_msgSender() == priceOracle, "bad caller");
        _;
    }

    function initialize(
        address _weth,
        address _oracle
    ) external initializer {
        require(_weth != address(0) && _oracle != address(0), "bad parameters");

        WETH = _weth;
        priceOracle = _oracle;
        MIN_BORROW_TIME = 5 minutes;

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    event NFTReceived(
        address indexed operator,
        address indexed from,
        uint256 indexed tokenId,
        bytes data
    );

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721HolderUpgradeable) returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function getBorrowId() internal returns (uint) {
        _borrowId.increment();
        return _borrowId.current();
    }

    event LogUpdateMinBorrowTime(uint time);
    function updateMinBorrowTime(uint _time) external onlyManager {
        MIN_BORROW_TIME = _time;
        emit LogUpdateMinBorrowTime(_time);
    }

    event LogUpdateCollectionMpa(
        address nft,
        uint apr,
        uint period,
        uint borrowRate,
        string slug,
        string name
    );
    function updateCollectionMap(
        address _nft,
        uint _apr,
        uint _period,
        uint _borrowRate,
        string memory _slug,
        string memory _name
    ) external onlyManager {

        require(_apr >= 100, "too low");
        require(_borrowRate >= 100, "too low");

        collectionMap[_nft] = NFTSeries({
            apr: _apr,
            slug: _slug,
            name: _name,
            period: _period,
            borrowRate: _borrowRate
        });
        supportNFT.add(_nft);

        emit LogUpdateCollectionMpa(_nft, _apr, _period, _borrowRate, _slug, _name);
    }

    event LogUpdateOracle(address oracle);
    function updatePriceOracle(address _oracle) external onlyManager {
        require(_oracle != address(0), "bad address");
        priceOracle = _oracle;
        emit LogUpdateOracle(_oracle);
    }

    event LogRemoveCollectionMap(address nft);
    function removeCollectionMap(address _nft) external onlyOwner {
        delete collectionMap[_nft];
        supportNFT.remove(_nft);
        emit LogRemoveCollectionMap(_nft);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function deposit(address _nft, uint _id)
        external
        nonReentrant
        whenNotPaused
    {
        require(supportNFT.contains(_nft), "not support yet");
        require(IERC721Upgradeable(_nft).ownerOf(_id) == _msgSender(), "not the owner");

        bytes32 requestId = IPriceOracle(priceOracle).requestNFTPrice(
            _nft,
            address(this),
            this.queryNFTPriceCB.selector
        );

        requestMap[requestId] = Request({
            user: _msgSender(),
            nft: _nft,
            id: _id
        });
    }

    event LogDeposit(uint indexed borrowId, address indexed user, address indexed nft, uint id, uint amount);
    event LogBalanceNotify(uint balance, uint borrowAmount);

    function queryNFTPriceCB(bytes32 _requestId, uint256 _price)
        external
        onlyPriceOracle
    {
        if (requestMap[_requestId].user != address(0) && _price > 0) {
            Request memory info = requestMap[_requestId];
            NFTSeries memory series = collectionMap[info.nft];

            uint borrowAmount = _price * series.borrowRate / BORROW_RATE_BASE;
            if (address(this).balance >= borrowAmount) {
                uint borrowId = getBorrowId();
                IERC721Upgradeable(info.nft).safeTransferFrom(
                    info.user,
                    address(this),
                    info.id
                );

                borrowMap[borrowId] = BorrowItem({
                    liquidateTime: block.timestamp + series.period,
                    startTime: block.timestamp,
                    status: Status.BORROW,
                    price: borrowAmount,
                    borrowId: borrowId,
                    user: info.user,
                    nft: info.nft,
                    id: info.id
                });

                userBorrowIdMap[info.user].add(borrowId);
                _safeTransferETHWithFallback(info.user, borrowAmount);

                emit LogDeposit(borrowId, info.user, info.nft, info.id, borrowAmount);
            } else {
                emit LogBalanceNotify(address(this).balance, borrowAmount);
            }
        }

        delete requestMap[_requestId];
    }

    function checkDepositIsExpired(uint borrowId)
        external
        view
        returns (bool)
    {
        BorrowItem memory borrowInfo = borrowMap[borrowId];

        return block.timestamp > borrowInfo.liquidateTime;
    }

    function calcRent(uint borrowId, uint end) external view returns(uint) {
        BorrowItem memory info = borrowMap[borrowId];

        NFTSeries memory series = collectionMap[info.nft];

        uint repayAmount = info.price +
            ((info.price * series.apr * (end - info.startTime)) / 365 days / APR_BASE);

        return repayAmount;
    }

    event LogRepay(uint indexed borrowId, address indexed user, address indexed nft, uint id, uint amount);

    function repay(uint borrowId) external payable nonReentrant {
        BorrowItem storage info = borrowMap[borrowId];

        require(block.timestamp - info.startTime > MIN_BORROW_TIME, "too fast");
        require(info.user == _msgSender() && info.status == Status.BORROW, "bad req");
        require(!this.checkDepositIsExpired(borrowId), "too late");

        uint repayAmount = this.calcRent(borrowId, block.timestamp);

        require(msg.value >= repayAmount, "bad amount");

        info.status = Status.REPAY;
        userBorrowIdMap[_msgSender()].remove(borrowId);

        IERC721Upgradeable(info.nft).safeTransferFrom(address(this), _msgSender(), info.id);

        // Refund left eth to user
        if (msg.value - repayAmount > 0) {
            _safeTransferETHWithFallback(_msgSender(), msg.value - repayAmount);
        }
        emit LogRepay(borrowId, _msgSender(), info.nft, info.id, repayAmount);
    }

    event LogWithdrawETH(address indexed receipt, uint amount);
    function withdrawETH(address receipt, uint _amount) external onlyOwner {
        uint amount = address(this).balance;
        require(amount >= _amount, "bad amount");
        _safeTransferETH(receipt, _amount);
        emit LogWithdrawETH(receipt, _amount);
    }

    event LogBidStart(uint indexed borrowId, address indexed user, address indexed nft, uint id, uint amount);
    function liquidation(uint borrowId)
        external
        payable
        nonReentrant
    {
        BorrowItem storage info = borrowMap[borrowId];

        require(info.user != address(0) && info.status == Status.BORROW, "bad req");
        require(this.checkDepositIsExpired(borrowId), "not expired");

        info.status = Status.AUCTION;
        userBorrowIdMap[info.user].remove(borrowId);

        uint repayAmount = this.calcRent(borrowId, info.liquidateTime);

        require(msg.value >= repayAmount, "bad amount");

        // operator is the first bidder
        auctionMap[borrowId] = Auction({
            endTime: block.timestamp + 24 hours,
            bidder: payable(_msgSender()),
            startTime: block.timestamp,
            borrowId: borrowId,
            amount: msg.value,
            settled: false
        });

        auctions.add(borrowId);

        emit LogBidStart(borrowId, _msgSender(), info.nft, info.id, repayAmount);
    }

    event LogCreateBid(uint indexed borrowId, address indexed user, uint amount);
    function createBid(uint borrowId) external payable nonReentrant {
        Auction storage _auction = auctionMap[borrowId];

        require(borrowMap[borrowId].status == Status.AUCTION, "bad status");
        require(!_auction.settled, "already settled");
        require(_auction.borrowId == borrowId, 'bad req');
        require(msg.value > _auction.amount, "bid price too low");
        require(block.timestamp < _auction.endTime, 'Auction expired');

        address payable lastBidder = _auction.bidder;
        if (lastBidder != address(0)) {
            // Refund the last bidder, if applicable
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
        }

        _auction.amount  = msg.value;
        _auction.endTime += 1 hours;
        _auction.bidder  = payable(msg.sender);

        emit LogCreateBid(borrowId, msg.sender, msg.value);
    }

    event LogClaimBidNFT(uint indexed borrowId, address indexed user);
    function claimBidNFT(uint borrowId) external nonReentrant {
        Auction storage _auction = auctionMap[borrowId];
        BorrowItem storage info = borrowMap[borrowId];

        require(info.status == Status.AUCTION, "bad status");
        require(!_auction.settled, 'already claimed');
        require(_auction.bidder == _msgSender(), 'bad req');
        require(block.timestamp > _auction.endTime, 'Auction not expired');

        _auction.settled = true;
        auctions.remove(borrowId);
        info.status = Status.WITHDRAW;

        IERC721Upgradeable(info.nft).safeTransferFrom(address(this), _msgSender(), info.id);

        emit LogClaimBidNFT(borrowId, _msgSender());
    }

    event LogWithdrawERC20(address receipt, address token, uint amount);
    function withdrawERC20(address receipt, address _token) external onlyOwner {
        uint amount = IERC20Upgradeable(_token).balanceOf(address(this));
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_token), receipt, amount);

        emit LogWithdrawERC20(receipt, _token, amount);
    }

    // for one NFT always no liquidation case, owner can withdraw nft to do other things
    event LogWithdrawNFT(uint indexed borrowId, address receipt, address nft, uint id);
    function withdrawNFT(uint borrowId, address receipt, address _nft, uint _id) external onlyOwner {
        BorrowItem storage info = borrowMap[borrowId];

        require(block.timestamp > info.liquidateTime, "not expired");
        require(info.user != address(0) && info.status == Status.BORROW, "bad req");

        info.status = Status.WITHDRAW;
        userBorrowIdMap[info.user].remove(borrowId);

        IERC721Upgradeable(_nft).safeTransferFrom(address(this), receipt, _id);

        emit LogWithdrawNFT(borrowId, receipt, _nft, _id);
    }

    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(WETH).deposit{value: amount}();
            require(IERC20Upgradeable(WETH).transfer(to, amount), "failed");
        }
    }

    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }

    fallback() external payable {}

    receive() external payable {}

    function getSupportNFT() external view returns (address[] memory) {
        return supportNFT.values();
    }

    function getAuctions() external view returns (uint[] memory) {
        return auctions.values();
    }

    function getRepayAmount(uint borrowId) external view returns(uint) {
        return this.calcRent(borrowId, block.timestamp);
    }

    function getUserBorrowList(address user) external view returns(uint[] memory) {
        return userBorrowIdMap[user].values();
    }
}
