const config = {
  contractAddress: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
  nftStorageKey: process.env.NFT_STORAGE_KEY || "YOUR_NFT_STORAGE_KEY",
  network: {
    chainId: 1337,
    name: "localhost",
    rpcUrl: "http://127.0.0.1:8545/"
  }
};

module.exports = config;
