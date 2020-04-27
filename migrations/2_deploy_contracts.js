const CashMockup = artifacts.require("CashMockup");
const aTokenMockup = artifacts.require("aTokenMockup");
const rTokenMockup = artifacts.require("rTokenMockup");
const CharityHodlFactory = artifacts.require("CharityHodlFactory");
const ClassicHodlFactory = artifacts.require("ClassicHodlFactory");
const PonziHodlFactory = artifacts.require("PonziHodlFactory");

const cashAddressRinkeby = '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa';
const cTokenAddressRinkeby = '0x6D7F0754FFeb405d23C51CE938289d4835bE3b14';
const rDaiCashAddressKovan = '0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa';
const rTokenAddressKovan = '0x462303f77a3f17Dbd95eb7bab412FE4937F9B9CB';
const aaveCashAddressKovan = '0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD';
const aaveAtokenAddressKovan = '0x58AD4cB396411B691A9AAb6F74545b2C5217FE6a';
const aaveLendingPoolAddressKovan = '0x580D4Fdc4BF8f9b5ae2fb9225D584fED4AD5375c';
const aaveLendingPoolCoreAddressKovan = '0x95D1189Ed88B380E319dF73fF00E479fcc4CFa45';

const WildcardsQV = artifacts.require("WildcardsQV");

const votingInterval = 120;
const LoyaltyTokenAddress = '0xd7d8c42ab5b83aa3d4114e5297989dc27bdfb715';
const WildcardTokenAddress = '0x6Da7DD22A9c1B6bC7b2Ba9A540A37EC786E30eA7';
const WildcardStewardAdress = '0x0C00CFE8EbB34fE7C31d4915a43Cde211e9F0F3B';
const dragonCardId = 13;

module.exports = function(deployer, network) {

  if (network === "rinkeby") {
    deployer.deploy(CharityHodlFactory, cashAddressRinkeby,cTokenAddressRinkeby);
  } else if (network === "kovan") {
    //classic
    deployer.deploy(ClassicHodlFactory, aaveCashAddressKovan, aaveAtokenAddressKovan,aaveLendingPoolAddressKovan,aaveLendingPoolCoreAddressKovan);
    //charity
    deployer.deploy(CharityHodlFactory, rDaiCashAddressKovan, rTokenAddressKovan);
    //ponzi
    deployer.deploy(PonziHodlFactory, aaveCashAddressKovan, aaveAtokenAddressKovan,aaveLendingPoolAddressKovan,aaveLendingPoolCoreAddressKovan);

  } else if (network === "goerli") {
    deployer.deploy(WildcardsQV, votingInterval, LoyaltyTokenAddress, WildcardTokenAddress, WildcardStewardAdress, dragonCardId);
  }  else {
    //classic
    deployer.deploy(CashMockup).then((deployedCash) => {
      return deployer.deploy(aTokenMockup, deployedCash.address).then((deployedaToken) => {
        return deployer.deploy(ClassicHodlFactory, deployedCash.address, deployedaToken.address, deployedaToken.address, deployedaToken.address);
       });
     });

     //charity
     deployer.deploy(CashMockup).then((deployedCash) => {
      return deployer.deploy(rTokenMockup, deployedCash.address).then((deployedrToken) => {
        return deployer.deploy(CharityHodlFactory, deployedCash.address, deployedrToken.address);
       });
     });

     //classic
     deployer.deploy(CashMockup).then((deployedCash) => {
      return deployer.deploy(aTokenMockup, deployedCash.address).then((deployedaToken) => {
        return deployer.deploy(PonziHodlFactory, deployedCash.address, deployedaToken.address, deployedaToken.address, deployedaToken.address);
       });
     });

  }


};
