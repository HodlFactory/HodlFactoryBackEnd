const CashMockup = artifacts.require("CashMockup");
const cTokenMockup = artifacts.require("cTokenMockup");
const ClassicHodlFactory = artifacts.require("ClassicHodlFactory");

contract('HodlFactoryTests', (accounts) => {

  beforeEach(async () => {
    cash = await CashMockup.new();
    cToken = await cTokenMockup.new(cash.address);
    hodlFactory = await ClassicHodlFactory.new(cash.address, cToken.address);
  });

  it('buyHodl', async () => {
      await hodlFactory.buyHodl();
  });

});
