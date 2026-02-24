// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@4.9.6/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts@4.9.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.9.6/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.6/utils/ReentrancyGuard.sol";

/**
 * @title BotMarketPlace
 * @dev Full marketplace: Buy/Sell, Subscriptions, Auctions
 */
contract BotMarketPlace is Ownable, ReentrancyGuard {
    
    // ============ ENUMS ============
    enum ProductType { Hardware, Service, Subscription }
    enum OrderStatus { Pending, Paid, Completed, Cancelled, Refunded }
    enum AuctionStatus { Active, Ended, Cancelled }
    enum SubscriptionStatus { Active, Expired, Cancelled }
    
    // ============ STATE ============
    
    // Platform
    uint256 public platformFee = 250; // 2.5%
    address public feeRecipient;
    
    // Supported tokens
    mapping(address => bool) public supportedTokens;
    address[] public tokenList;
    
    // Product counters
    uint256 public productCount;
    uint256 public orderCount;
    uint256 public auctionCount;
    uint256 public subscriptionCount;
    
    // ============ STRUCTS ============
    
    struct Product {
        uint256 id;
        string name;
        string description;
        string imageUrl;
        ProductType productType;
        uint256 price; // in USD (stored as cents)
        address seller;
        bool isActive;
        uint256 createdAt;
        // For subscriptions
        uint256 monthlyPrice; // price per month
        uint256 durationDays; // subscription duration
    }
    
    struct Order {
        uint256 id;
        uint256 productId;
        address buyer;
        uint256 amount;
        address token;
        OrderStatus status;
        uint256 createdAt;
        uint256 paidAt;
    }
    
    struct Auction {
        uint256 id;
        uint256 productId;
        address seller;
        uint256 startingPrice;
        uint256 currentBid;
        address highestBidder;
        uint256 endTime;
        AuctionStatus status;
        address[] bidders;
    }
    
    struct Subscription {
        uint256 id;
        uint256 productId;
        address subscriber;
        uint256 startTime;
        uint256 endTime;
        SubscriptionStatus status;
        bool autoRenew;
    }
    
    // ============ MAPPINGS ============
    
    mapping(uint256 => Product) public products;
    mapping(uint256 => Order) public orders;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Subscription) public subscriptions;
    
    mapping(address => uint256[]) public userOrders;
    mapping(address => uint256[]) public userAuctions;
    mapping(address => uint256[]) public userSubscriptions;
    mapping(address => uint256[]) public userProducts;
    
    // ============ EVENTS ============
    
    event ProductCreated(uint256 indexed id, string name, address indexed seller, uint256 price);
    event ProductUpdated(uint256 indexed id);
    event ProductDeleted(uint256 indexed id);
    
    event OrderCreated(uint256 indexed orderId, address indexed buyer, uint256 productId, uint256 amount);
    event OrderPaid(uint256 indexed orderId, address indexed buyer, uint256 amount);
    event OrderCompleted(uint256 indexed orderId);
    event OrderCancelled(uint256 indexed orderId);
    
    event AuctionCreated(uint256 indexed auctionId, uint256 productId, uint256 startingPrice, uint256 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 finalPrice);
    event AuctionCancelled(uint256 indexed auctionId);
    
    event SubscriptionCreated(uint256 indexed subId, address indexed subscriber, uint256 productId, uint256 endTime);
    event SubscriptionRenewed(uint256 indexed subId, uint256 newEndTime);
    event SubscriptionCancelled(uint256 indexed subId);
    
    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event FeeUpdated(uint256 newFee);

    // ============ CONSTRUCTOR ============
    
    constructor(address _feeRecipient) Ownable(msg.sender) {
        feeRecipient = _feeRecipient;
    }

    // ============ TOKEN MANAGEMENT ============
    
    modifier onlySupportedToken(address token) {
        require(supportedTokens[token], "Token not supported");
        _;
    }
    
    function addToken(address token) external onlyOwner {
        require(token != address(0), "Invalid address");
        require(!supportedTokens[token], "Already supported");
        supportedTokens[token] = true;
        tokenList.push(token);
        emit TokenAdded(token);
    }
    
    function removeToken(address token) external onlyOwner {
        require(supportedTokens[token], "Not supported");
        supportedTokens[token] = false;
        emit TokenRemoved(token);
    }
    
    function setPlatformFee(uint256 _fee) external onlyOwner {
        require(_fee <= 1000, "Fee too high");
        platformFee = _fee;
        emit FeeUpdated(_fee);
    }
    
    function setFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "Invalid address");
        feeRecipient = _recipient;
    }

    // ============ PRODUCTS (BUY/SELL) ============
    
    function createProduct(
        string memory name,
        string memory description,
        string memory imageUrl,
        ProductType productType,
        uint256 price,
        uint256 monthlyPrice,
        uint256 durationDays
    ) external returns (uint256) {
        productCount++;
        
        products[productCount] = Product({
            id: productCount,
            name: name,
            description: description,
            imageUrl: imageUrl,
            productType: productType,
            price: price,
            seller: msg.sender,
            isActive: true,
            createdAt: block.timestamp,
            monthlyPrice: monthlyPrice,
            durationDays: durationDays
        });
        
        userProducts[msg.sender].push(productCount);
        
        emit ProductCreated(productCount, name, msg.sender, price);
        return productCount;
    }
    
    function updateProduct(uint256 productId, string memory name, string memory description, uint256 price) external {
        Product storage product = products[productId];
        require(product.seller == msg.sender || msg.sender == owner(), "Not authorized");
        require(product.isActive, "Product not active");
        
        product.name = name;
        product.description = description;
        product.price = price;
        
        emit ProductUpdated(productId);
    }
    
    function deleteProduct(uint256 productId) external {
        Product storage product = products[productId];
        require(product.seller == msg.sender || msg.sender == owner(), "Not authorized");
        product.isActive = false;
        emit ProductDeleted(productId);
    }
    
    function getProduct(uint256 productId) external view returns (Product memory) {
        return products[productId];
    }
    
    function getProductsBySeller(address seller) external view returns (uint256[] memory) {
        return userProducts[seller];
    }

    // ============ ORDERS (BUY NOW) ============
    
    function createOrder(uint256 productId, address token) 
        external 
        nonReentrant 
        onlySupportedToken(token) 
        returns (uint256) 
    {
        Product memory product = products[productId];
        require(product.isActive, "Product not active");
        require(product.productType != ProductType.Subscription, "Use subscription for recurring");
        
        orderCount++;
        
        orders[orderCount] = Order({
            id: orderCount,
            productId: productId,
            buyer: msg.sender,
            amount: product.price,
            token: token,
            status: OrderStatus.Pending,
            createdAt: block.timestamp,
            paidAt: 0
        });
        
        userOrders[msg.sender].push(orderCount);
        
        emit OrderCreated(orderCount, msg.sender, productId, product.price);
        return orderCount;
    }
    
    function payOrder(uint256 orderId) external nonReentrant {
        Order storage order = orders[orderId];
        require(order.buyer == msg.sender, "Not buyer");
        require(order.status == OrderStatus.Pending, "Not pending");
        
        Product memory product = products[order.productId];
        
        // Transfer tokens
        require(
            IERC20(order.token).transferFrom(msg.sender, address(this), order.amount),
            "Transfer failed"
        );
        
        order.status = OrderStatus.Paid;
        order.paidAt = block.timestamp;
        
        emit OrderPaid(orderId, msg.sender, order.amount);
    }
    
    function completeOrder(uint256 orderId) external nonReentrant {
        Order storage order = orders[orderId];
        require(order.status == OrderStatus.Paid, "Not paid");
        
        Product memory product = products[order.productId];
        require(product.seller == msg.sender || msg.sender == owner(), "Not authorized");
        
        // Calculate fees and transfer to seller
        uint256 fee = (order.amount * platformFee) / 10000;
        uint256 sellerAmount = order.amount - fee;
        
        require(
            IERC20(order.token).transfer(feeRecipient, fee),
            "Fee transfer failed"
        );
        require(
            IERC20(order.token).transfer(product.seller, sellerAmount),
            "Seller transfer failed"
        );
        
        order.status = OrderStatus.Completed;
        
        emit OrderCompleted(orderId);
    }
    
    function cancelOrder(uint256 orderId) external {
        Order storage order = orders[orderId];
        require(order.buyer == msg.sender || msg.sender == owner(), "Not authorized");
        require(order.status == OrderStatus.Pending, "Cannot cancel");
        
        order.status = OrderStatus.Cancelled;
        emit OrderCancelled(orderId);
    }

    // ============ AUCTIONS ============
    
    function createAuction(
        uint256 productId,
        uint256 startingPrice,
        uint256 durationHours,
        address token
    ) external onlySupportedToken(token) returns (uint256) {
        Product memory product = products[productId];
        require(product.isActive, "Product not active");
        
        auctionCount++;
        
        uint256 endTime = block.timestamp + (durationHours * 1 hours);
        
        auctions[auctionCount] = Auction({
            id: auctionCount,
            productId: productId,
            seller: msg.sender,
            startingPrice: startingPrice,
            currentBid: startingPrice,
            highestBidder: address(0),
            endTime: endTime,
            status: AuctionStatus.Active,
            bidders: new address[](0)
        });
        
        userAuctions[msg.sender].push(auctionCount);
        
        emit AuctionCreated(auctionCount, productId, startingPrice, endTime);
        return auctionCount;
    }
    
    function placeBid(uint256 auctionId, address token) 
        external 
        nonReentrant 
        onlySupportedToken(token) 
    {
        Auction storage auction = auctions[auctionId];
        require(auction.status == AuctionStatus.Active, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        
        // Get bid amount from user (in real implementation, would use msg.value or token transfer)
        // For now, assuming bid amount is passed differently
        uint256 bidAmount = auction.currentBid + (auction.currentBid / 10); // 10% increment
        
        require(bidAmount > auction.currentBid, "Bid too low");
        
        // Return previous highest bid if any
        if (auction.highestBidder != address(0)) {
            // In real implementation, return previous bid
        }
        
        auction.highestBidder = msg.sender;
        auction.currentBid = bidAmount;
        auction.bidders.push(msg.sender);
        
        emit BidPlaced(auctionId, msg.sender, bidAmount);
    }
    
    function endAuction(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.status == AuctionStatus.Active, "Not active");
        require(block.timestamp >= auction.endTime, "Not ended");
        
        auction.status = AuctionStatus.Ended;
        
        if (auction.highestBidder != address(0)) {
            // Calculate and transfer fees
            uint256 fee = (auction.currentBid * platformFee) / 10000;
            uint256 sellerAmount = auction.currentBid - fee;
            
            // In real implementation, transfer tokens here
            
            emit AuctionEnded(auctionId, auction.highestBidder, auction.currentBid);
        } else {
            emit AuctionEnded(auctionId, address(0), 0);
        }
    }
    
    function cancelAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        require(auction.seller == msg.sender || msg.sender == owner(), "Not authorized");
        require(auction.status == AuctionStatus.Active, "Not active");
        
        auction.status = AuctionStatus.Cancelled;
        emit AuctionCancelled(auctionId);
    }

    // ============ SUBSCRIPTIONS ============
    
    function createSubscription(uint256 productId, address token, bool autoRenew)
        external
        nonReentrant
        onlySupportedToken(token)
        returns (uint256)
    {
        Product memory product = products[productId];
        require(product.isActive, "Product not active");
        require(product.productType == ProductType.Subscription, "Not a subscription");
        require(product.monthlyPrice > 0, "No subscription price");
        
        // Calculate total price
        uint256 totalPrice = product.monthlyPrice * product.durationDays / 30;
        
        // Transfer tokens
        require(
            IERC20(token).transferFrom(msg.sender, address(this), totalPrice),
            "Transfer failed"
        );
        
        subscriptionCount++;
        
        uint256 endTime = block.timestamp + (product.durationDays * 1 days);
        
        subscriptions[subscriptionCount] = Subscription({
            id: subscriptionCount,
            productId: productId,
            subscriber: msg.sender,
            startTime: block.timestamp,
            endTime: endTime,
            status: SubscriptionStatus.Active,
            autoRenew: autoRenew
        });
        
        userSubscriptions[msg.sender].push(subscriptionCount);
        
        emit SubscriptionCreated(subscriptionCount, msg.sender, productId, endTime);
        return subscriptionCount;
    }
    
    function renewSubscription(uint256 subId) external nonReentrant {
        Subscription storage sub = subscriptions[subId];
        require(sub.subscriber == msg.sender, "Not subscriber");
        
        Product memory product = products[sub.productId];
        require(product.isActive, "Product not active");
        
        uint256 renewalPrice = product.monthlyPrice * product.durationDays / 30;
        
        // Process payment (simplified)
        sub.endTime = sub.endTime + (product.durationDays * 1 days);
        
        emit SubscriptionRenewed(subId, sub.endTime);
    }
    
    function cancelSubscription(uint256 subId) external {
        Subscription storage sub = subscriptions[subId];
        require(sub.subscriber == msg.sender || msg.sender == owner(), "Not authorized");
        
        sub.status = SubscriptionStatus.Cancelled;
        emit SubscriptionCancelled(subId);
    }
    
    function checkSubscriptionStatus(uint256 subId) external view returns (bool isActive) {
        Subscription memory sub = subscriptions[subId];
        return sub.status == SubscriptionStatus.Active && block.timestamp < sub.endTime;
    }

    // ============ GETTERS ============
    
    function getSupportedTokens() external view returns (address[] memory) {
        return tokenList;
    }
    
    function getUserOrders(address user) external view returns (uint256[] memory) {
        return userOrders[user];
    }
    
    function getUserAuctions(address user) external view returns (uint256[] memory) {
        return userAuctions[user];
    }
    
    function getUserSubscriptions(address user) external view returns (uint256[] memory) {
        return userSubscriptions[user];
    }
    
    function getActiveProducts() external view returns (uint256[] memory productIds) {
        uint256[] memory result = new uint256[](productCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= productCount; i++) {
            if (products[i].isActive) {
                result[count] = i;
                count++;
            }
        }
        return result;
    }
}
