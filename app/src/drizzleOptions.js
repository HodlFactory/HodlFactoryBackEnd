import Web3 from "web3";
import ComplexStorage from "./contracts/ComplexStorage.json";
import SimpleStorage from "./contracts/SimpleStorage.json";
import TutorialToken from "./contracts/TutorialToken.json";
import ClassicHodlFactory from "./contracts/ClassicHodlFactory.json";

const fallbackUrl =
  "wss://rinkeby.infura.io/ws/v3/e811479f4c414e219e7673b6671c2aba";

const options = {
  web3: {
    block: false,
    fallback: {
      type: "ws",
      url: fallbackUrl
    }
    // customProvider: new Web3("ws://localhost:8545"),
  },
  contracts: [SimpleStorage, ComplexStorage, TutorialToken,ClassicHodlFactory],
  events: {
    SimpleStorage: ["StorageSet"],
  },
};

export default options;
