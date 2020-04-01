const CashMockup = artifacts.require("CashMockup");
const cTokenMockup = artifacts.require("cTokenMockup");
const ClassicHodlFactory = artifacts.require("ClassicHodlFactory");

contract('HodlFactoryTests', (accounts) => {

  user = accounts[0];

  beforeEach(async () => {
    cash = await CashMockup.new();
    cToken = await cTokenMockup.new(cash.address);
    hodlFactory = await ClassicHodlFactory.new(cash.address, cToken.address);
  });

  it('buyHodl', async () => {
    await hodlFactory.buyHodl();
    // check that 100 Dai allocated
    var daiBalance = await cash.balanceOf.call(cToken.address);
    assert.equal(web3.utils.toWei('100', 'ether'), daiBalance);
    // check that 5000 cDai allocated
    var cTokenBalance = await cToken.balanceOf.call(hodlFactory.address);
    cTokenBalance = cTokenBalance * 10000000000;
    assert.equal(web3.utils.toWei('5000', 'ether'), cTokenBalance);
    // check that hodlTracker is good
    var hodlOwner = await hodlFactory.getHodlOwner.call(0);
    assert.equal(user, hodlOwner);
    var hodlTokenBalance = await hodlFactory.getHodlTokenBalance.call(0);
    assert.equal(web3.utils.toWei('5000', 'ether'), hodlTokenBalance);
    //check NFT owner
    var owner = await hodlFactory.ownerOf.call(0);
    assert.equal(owner, user);
  });

  it('check getFxRateTimesOneThousand', async () => {
    await hodlFactory.buyHodl();
    var getFxRate = await hodlFactory.getFxRateTimesOneThousand.call();
    assert.equal(getFxRate, 50000);
    await cToken.generate10PercentInterest(hodlFactory.address);
    var getFxRate = await hodlFactory.getFxRateTimesOneThousand.call();
    assert.equal(getFxRate, 45454); //= 5000 / 110 * 1000 rounded down
  });

  // it('check interestAvailableToWithdraw', async () => {
  //   await hodlFactory.buyHodl();
  //   var interestAvailable = await hodlFactory.interestAvailableToWithdraw.call(0)
  //   assert.equal(interestAvailable, 0);
  // });
});
