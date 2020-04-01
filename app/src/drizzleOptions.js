import Web3 from "web3";
import ComplexStorage from "./contracts/ComplexStorage.json";
import SimpleStorage from "./contracts/SimpleStorage.json";
import SimpleStorage2 from "./contracts/SimpleStorage2.json";
import TutorialToken from "./contracts/TutorialToken.json";
import ClassicHodlFactory from "./contracts/ClassicHodlFactory.json";
import CashMockup from "./contracts/CashMockup.json";

const options = {
  web3: {
    block: false,
    customProvider: new Web3("ws://localhost:8545"),
  },
  contracts: [ClassicHodlFactory, SimpleStorage, ComplexStorage, TutorialToken, SimpleStorage2, CashMockup],
  events: {
    SimpleStorage: ["StorageSet"],
  },
};

export default options;
