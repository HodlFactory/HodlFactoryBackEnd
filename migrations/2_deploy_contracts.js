const CashMockup = artifacts.require("CashMockup");
const cTokenMockup = artifacts.require("cTokenMockup");
const CharityHodlFactory = artifacts.require("CharityHodlFactory");
const ClassicHodlFactory = artifacts.require("ClassicHodlFactory");

const cashAddressRinkeby = '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa';
const cTokenAddressRinkeby = '0x6D7F0754FFeb405d23C51CE938289d4835bE3b14';
const cashAddressKovan = '0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa';
const rTokenAddressKovan = '0x462303f77a3f17Dbd95eb7bab412FE4937F9B9CB';

module.exports = function(deployer, network) {

  if (network === "rinkeby") {
    deployer.deploy(ClassicHodlFactory, cashAddressRinkeby,cTokenAddressRinkeby);

  } else if (network === "kovan") {
    deployer.deploy(CharityHodlFactory, cashAddressKovan,rTokenAddressKovan);
  } else {
    deployer.deploy(CashMockup).then((deployedCash) => {
      return deployer.deploy(cTokenMockup, deployedCash.address).then((deployedcToken) => {
        return deployer.deploy(ClassicHodlFactory, deployedCash.address, deployedcToken.address);
       });
     });
  }
};
