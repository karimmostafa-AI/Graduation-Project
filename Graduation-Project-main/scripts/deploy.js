const hre = require("hardhat");

async function main() {
  // Get the contract factory
  const GovernmentPropertyVerification = await hre.ethers.getContractFactory("GovernmentPropertyVerification");

  // Deploy the contract
  const contract = await GovernmentPropertyVerification.deploy();

  // Wait for deployment to finish
  await contract.waitForDeployment();

  // Get the deployed contract address
  const contractAddress = await contract.getAddress();

  console.log("GovernmentPropertyVerification deployed to:", contractAddress);

  // Optional: Verify the deployment
  console.log("Contract owner:", await contract.owner());
}

// Handle errors
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});