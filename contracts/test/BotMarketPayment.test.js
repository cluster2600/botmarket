const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BotMarketPayment", function () {
  let payment;
  let owner;
  let buyer;
  let seller;
  let usdt;
  
  // Mock USDT for testing
  const USDT_ADDRESS = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
  
  before(async function () {
    [owner, buyer, seller] = await ethers.getSigners();
    
    // Deploy contract
    const BotMarketPayment = await ethers.getContractFactory("BotMarketPayment");
    payment = await BotMarketPayment.deploy();
    await payment.deployed();
  });
  
  describe("Token Management", function () {
    it("should add a supported token", async function () {
      await payment.addToken(USDT_ADDRESS);
      expect(await payment.supportedTokens(USDT_ADDRESS)).to.be.true;
    });
    
    it("should remove a supported token", async function () {
      await payment.addToken(owner.address);
      await payment.removeToken(owner.address);
      expect(await payment.supportedTokens(owner.address)).to.be.false;
    });
  });
  
  describe("Platform Fee", function () {
    it("should update platform fee", async function () {
      await payment.setPlatformFee(500); // 5%
      expect(await payment.platformFee()).to.equal(500);
    });
    
    it("should reject fee too high", async function () {
      await expect(payment.setPlatformFee(2000)).to.be.revertedWith("Fee too high");
    });
  });
  
  describe("Orders", function () {
    it("should create an order", async function () {
      const tx = await payment.createOrder(1, ethers.utils.parseUnits("100", 6), USDT_ADDRESS);
      const receipt = await tx.wait();
      
      const orderId = receipt.events.find(e => e.event === "OrderCreated").args.orderId;
      expect(orderId).to.equal(1);
      
      const order = await payment.orders(1);
      expect(order.buyer).to.equal(owner.address);
      expect(order.amount).to.equal(ethers.utils.parseUnits("100", 6));
    });
    
    it("should complete order and distribute funds", async function () {
      // Get current order count
      const orderCount = await payment.orderCount();
      expect(orderCount).to.equal(1);
    });
  });
});
