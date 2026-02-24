const hre = require("hardhat");

// Token addresses (mainnet)
const TOKENS = {
  // Ethereum mainnet
  "1": {
    USDT: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
    USDC: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    DAI: "0x6B175474E89094C44Da98b954EedeAC495271d0F"
  },
  // Polygon
  "137": {
    USDT: "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
    USDC: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
  },
  // Sepolia (testnet)
  "11155111": {
    // Would need testnet token addresses
  }
};

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  
  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  
  // Deploy BotMarketPayment
  console.log("\nDeploying BotMarketPayment...");
  const BotMarketPayment = await hre.ethers.getContractFactory("BotMarketPayment");
  const payment = await BotMarketPayment.deploy();
  
  await payment.deployed();
  console.log("BotMarketPayment deployed to:", payment.address);
  
  // Get chain ID
  const chainId = (await hre.ethers.provider.getNetwork()).chainId;
  const chainIdHex = chainId.toNumber();
  
  // Add supported tokens
  const tokenAddresses = TOKENS[chainIdHex] || {};
  for (const [name, address] of Object.entries(tokenAddresses)) {
    console.log(`Adding ${name} (${address})...`);
    try {
      const tx = await payment.addToken(address);
      await tx.wait();
      console.log(`${name} added!`);
    } catch (e) {
      console.log(`Could not add ${name}:`, e.message);
    }
  }
  
  // Verify on Etherscan
  if (chainIdHex !== 31337 && chainIdHex !== 1) {
    console.log("\nWaiting for block confirmation...");
    await payment.deployTransaction.wait(6);
    
    console.log("Verifying on Etherscan...");
    try {
      await hre.run("verify:verify", {
        address: payment.address,
        constructorArguments: []
      });
      console.log("Verified!");
    } catch (e) {
      console.log("Verification failed:", e.message);
    }
  }
  
  console.log("\n=== Deployment Summary ===");
  console.log("Network:", hre.network.name, "(chainId:", chainIdHex + ")");
  console.log("Contract:", payment.address);
  console.log("Supported tokens:", Object.keys(tokenAddresses).join(", "));
  
  // Save deployment info
  const deploymentInfo = {
    network: hre.network.name,
    chainId: chainIdHex,
    contract: "BotMarketPayment",
    address: payment.address,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    tokens: tokenAddresses
  };
  
  const fs = require("fs");
  fs.writeFileSync(
    "./deployment.json",
    JSON.stringify(deploymentInfo, null, 2)
  );
  
  console.log("\nDeployment info saved to deployment.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
