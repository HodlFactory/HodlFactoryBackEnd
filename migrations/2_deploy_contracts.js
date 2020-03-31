const SimpleStorage = artifacts.require("SimpleStorage");
const TutorialToken = artifacts.require("TutorialToken");
const ComplexStorage = artifacts.require("ComplexStorage");
const CashMockup = artifacts.require("CashMockup");
const cTokenMockup = artifacts.require("cTokenMockup");
const ClassicHodlFactory = artifacts.require("ClassicHodlFactory");

const cashAddressRinkeby = '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa';
const cTokenAddressRinkeby = '0x6D7F0754FFeb405d23C51CE938289d4835bE3b14';

module.exports = function(deployer, network) {

  if (network === "rinkeby") {

    deployer.deploy(ClassicHodlFactory, cashAddressRinkeby,cTokenAddressRinkeby);

  } else {

    // deployer.deploy(SimpleStorage);
    // deployer.deploy(TutorialToken);
    // deployer.deploy(ComplexStorage);
    deployer.deploy(CashMockup).then((deployedCash) => {
      return deployer.deploy(cTokenMockup, deployedCash.address).then((deployedcToken) => {
        return deployer.deploy(ClassicHodlFactory, deployedCash.address, deployedcToken.address);
       });
     });
  }
};
