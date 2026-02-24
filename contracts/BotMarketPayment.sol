// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@4.9.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.9.6/access/Ownable.sol";

/**
 * @title BotMarketPayment
 * @dev Smart contract for marketplace payments with stablecoins
 */
contract BotMarketPayment is Ownable {
    
    // Supported stablecoins
    mapping(address => bool) public supportedTokens;
    address[] public tokenList;
    
    // Platform fee (in basis points, 100 = 1%)
    uint256 public platformFee = 250; // 2.5%
    
    // Order states
    enum OrderStatus {
        Pending,
        Paid,
        Completed,
        Cancelled,
        Refunded
    }
    
    // Product types
    enum ProductType {
        Hardware,      // AWS instances
        Service,      // AI bots, trading bots
        Subscription  // Monthly plans
    }
    
    // Order struct
    struct Order {
        uint256 id;
        address buyer;
        uint256 productId;
        uint256 amount;
        address token;
        OrderStatus status;
        uint256 createdAt;
        uint256 paidAt;
    }
    
    // Events
    event OrderCreated(uint256 indexed orderId, address indexed buyer, uint256 productId, uint256 amount, address token);
    event OrderPaid(uint256 indexed orderId, address indexed buyer, uint256 amount, address token, bytes32 txHash);
    event OrderCompleted(uint256 indexed orderId);
    event OrderCancelled(uint256 indexed orderId);
    event OrderRefunded(uint256 indexed orderId);
    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event FeeUpdated(uint256 newFee);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    // Mappings
    mapping(uint256 => Order) public orders;
    mapping(address => uint256[]) public userOrders;
    mapping(address => uint256) public pendingWithdrawals;
    
    uint256 public orderCount;
    
    constructor() Ownable(msg.sender) {
        // Add supported tokens (USDT, USDC, DAI on Ethereum mainnet)
        // These would be set after deployment based on chain
    }
    
    // Modifier
    modifier onlyValidToken(address token) {
        require(supportedTokens[token], "Token not supported");
        _;
    }
    
    // Add supported token
    function addToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(!supportedTokens[token], "Token already supported");
        
        supportedTokens[token] = true;
        tokenList.push(token);
        
        emit TokenAdded(token);
    }
    
    // Remove token
    function removeToken(address token) external onlyOwner {
        require(supportedTokens[token], "Token not supported");
        
        supportedTokens[token] = false;
        
        emit TokenRemoved(token);
    }
    
    // Update platform fee
    function setPlatformFee(uint256 _fee) external onlyOwner {
        require(_fee <= 1000, "Fee too high"); // Max 10%
        platformFee = _fee;
        emit FeeUpdated(_fee);
    }
    
    // Create order
    function createOrder(
        uint256 productId,
        uint256 amount,
        address token
    ) external onlyValidToken(token) returns (uint256) {
        require(amount > 0, "Amount must be greater than 0");
        
        orderCount++;
        
        orders[orderCount] = Order({
            id: orderCount,
            buyer: msg.sender,
            productId: productId,
            amount: amount,
            token: token,
            status: OrderStatus.Pending,
            createdAt: block.timestamp,
            paidAt: 0
        });
        
        userOrders[msg.sender].push(orderCount);
        
        emit OrderCreated(orderCount, msg.sender, productId, amount, token);
        
        return orderCount;
    }
    
    // Pay order
    function payOrder(uint256 orderId, bytes32 txHash) external {
        Order storage order = orders[orderId];
        
        require(order.buyer == msg.sender, "Not the buyer");
        require(order.status == OrderStatus.Pending, "Order not pending");
        
        // Transfer tokens from buyer to contract
        IERC20(order.token).transferFrom(msg.sender, address(this), order.amount);
        
        order.status = OrderStatus.Paid;
        order.paidAt = block.timestamp;
        
        emit OrderPaid(orderId, msg.sender, order.amount, order.token, txHash);
    }
    
    // Complete order (called by seller after service delivered)
    function completeOrder(uint256 orderId) external onlyOwner {
        Order storage order = orders[orderId];
        
        require(order.status == OrderStatus.Paid, "Order not paid");
        
        order.status = OrderStatus.Completed;
        
        // Calculate fees
        uint256 fee = (order.amount * platformFee) / 10000;
        uint256 sellerAmount = order.amount - fee;
        
        // Add to seller's pending withdrawals
        pendingWithdrawals[owner()] += fee;
        pendingWithdrawals[order.buyer] += sellerAmount; // In real scenario, this goes to seller
        
        emit OrderCompleted(orderId);
    }
    
    // Cancel order
    function cancelOrder(uint256 orderId) external {
        Order storage order = orders[orderId];
        
        require(order.buyer == msg.sender || msg.sender == owner(), "Not authorized");
        require(order.status == OrderStatus.Pending, "Cannot cancel");
        
        order.status = OrderStatus.Cancelled;
        
        emit OrderCancelled(orderId);
    }
    
    // Refund order
    function refundOrder(uint256 orderId) external onlyOwner {
        Order storage order = orders[orderId];
        
        require(order.status == OrderStatus.Paid, "Order not paid");
        
        // Refund buyer
        IERC20(order.token).transfer(order.buyer, order.amount);
        
        order.status = OrderStatus.Refunded;
        
        emit OrderRefunded(orderId);
    }
    
    // Withdraw funds
    function withdraw() external {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        pendingWithdrawals[msg.sender] = 0;
        
        // In real scenario, would need to handle multiple tokens
        payable(msg.sender).transfer(amount);
        
        emit FundsWithdrawn(msg.sender, amount);
    }
    
    // Withdraw ERC20 tokens
    function withdrawToken(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        
        IERC20(token).transfer(owner(), balance);
    }
    
    // Get supported tokens
    function getSupportedTokens() external view returns (address[] memory) {
        return tokenList;
    }
    
    // Get user order count
    function getUserOrderCount(address user) external view returns (uint256) {
        return userOrders[user].length;
    }
    
    // Get order details
    function getOrder(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    }
}
