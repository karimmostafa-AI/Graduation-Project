// Convert from ES modules to CommonJS
const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const nftStorageKey = "YOUR_NFT_STORAGE_KEY";

const networkConfig = {
  chainId: 1337,
  name: "localhost",
  rpcUrl: "http://127.0.0.1:8545/"
};

module.exports = {
  contractAddress,
  nftStorageKey,
  networkConfig
};
