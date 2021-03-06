const path = require("path");
const HDWalletProvider = require('truffle-hdwallet-provider');
const mnemonic = 'defense ready lady corn other ride rapid collect avocado tongue price nut'; // pls dont steal my testnet ether 
// const mnemonic = 'case priority seek winter uphold brother alarm various glide run soul fork'; // pls dont steal my testnet ether 
const mainnetProviderUrl = 'https://mainnet.infura.io/v3/e811479f4c414e219e7673b6671c2aba'; 
const rinkebyProviderUrl = 'https://rinkeby.infura.io/v3/e811479f4c414e219e7673b6671c2aba';
const kovanProviderUrl = 'https://kovan.infura.io/v3/e811479f4c414e219e7673b6671c2aba';
const goerliProviderUrl = 'https://goerli.infura.io/v3/e811479f4c414e219e7673b6671c2aba';

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, "app/src/contracts"),
  networks: {
    develop: { // default with truffle unbox is 7545, but we can use develop to test changes, ex. truffle migrate --network develop
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    },
    rinkeby: {
      network_id: 4,
      provider: new HDWalletProvider(mnemonic, rinkebyProviderUrl, 0),
      // gas: 10000000,
      gasPrice: 10000000000, // 10 gwei
      skipDryRun: true,
    },
    kovan: {
      network_id: 42,
      provider: new HDWalletProvider(mnemonic, kovanProviderUrl, 0),
      // gas: 10000000,
      gasPrice: 10000000000, // 10 gwei
      skipDryRun: true,
      // networkCheckTimeout: 10,
    },
    goerli: {
      network_id: 5,
      provider: new HDWalletProvider(mnemonic, goerliProviderUrl, 0),
      gas: 8000000,
      gasPrice: 100000000, 
      skipDryRun: true,
    }
  }
};
