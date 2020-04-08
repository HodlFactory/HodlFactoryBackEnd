const CashMockup = artifacts.require("CashMockup");
const aTokenMockup = artifacts.require("aTokenMockup");
const ClassicHodlFactory = artifacts.require("ClassicHodlFactory");

contract('HodlFactoryTests', (accounts) => {

  user = accounts[0];

  beforeEach(async () => {
    cash = await CashMockup.new();
    aToken = await aTokenMockup.new(cash.address);
    hodlFactory = await ClassicHodlFactory.new(cash.address, aToken.address, aToken.address, aToken.address);
  });

  it('createHodl', async () => {
    await hodlFactory.createHodl();
    var hodlCount = await hodlFactory.hodlCount.call();
    assert.equal(hodlCount,1);
    // check that 100 Dai allocated
    var daiBalance = await cash.balanceOf.call(aToken.address);
    assert.equal(web3.utils.toWei('100', 'ether'), daiBalance);
    // check that 100 aDai allocated
    var aTokenBalance = await aToken.balanceOf.call(hodlFactory.address);
    assert.equal(web3.utils.toWei('100', 'ether'), aTokenBalance);
    // check that hodlTracker is good
    var hodlOwner = await hodlFactory.ownerOf.call(0);
    assert.equal(user, hodlOwner);
  });

  it('check getInterestAvailableToWithdraw', async () => {
    await hodlFactory.createHodl();
    var hodlCount = await hodlFactory.hodlCount.call();
    assert.equal(hodlCount,1);
    await aToken.generate10PercentInterest(hodlFactory.address);
    await hodlFactory.getInterestAvailableToWithdraw.call(0);
    var hodlCount = await hodlFactory.hodlCount.call();
    assert.equal(hodlCount,1);
    var testingVariableA = await hodlFactory.testingVariableA.call();
    console.log(testingVariableA);
    // var testingVariableB = await hodlFactory.testingVariableB.call();
    // console.log(testingVariableB);
    // var testingVariableC = await hodlFactory.testingVariableC.call();
    // console.log(testingVariableC);
  });

  // it('check getFxRateTimesOneThousand', async () => {
  //   await hodlFactory.buyHodl();
  //   var getFxRate = await hodlFactory.getFxRateTimesOneThousand.call();
  //   assert.equal(getFxRate, 50000);
  //   await aToken.generate10PercentInterest(hodlFactory.address);
  //   var getFxRate = await hodlFactory.getFxRateTimesOneThousand.call();
  //   assert.equal(getFxRate, 45454); //= 5000 / 110 * 1000 rounded down
  // });

  // it('check getActualinterestAvailableToWithdraw', async () => {
  //   await hodlFactory.buyHodl();
  //   var interestAvailable = await hodlFactory.getActualinterestAvailableToWithdraw.call(0)
  //   assert.equal(interestAvailable, 0);
  //   await aToken.generate10PercentInterest(hodlFactory.address);
  //   var interestAvailable = await hodlFactory.getActualinterestAvailableToWithdraw.call(0)
  //   var difference = interestAvailable - web3.utils.toWei('10', 'ether');
  //   assert.isBelow(difference/interestAvailable,0.001);
  // });

  // it('test withdrawInterest', async() => {
  //   await hodlFactory.buyHodl();
  //   await aToken.generate10PercentInterest(hodlFactory.address);
  //   // check aToken has 110 dai left
  //   var daiBalance = await cash.balanceOf(aToken.address);
  //   var difference = daiBalance - web3.utils.toWei('120', 'ether');
  //   assert.isBelow(difference/daiBalance,0.001);
  //   // check hdolFactory has 5000 cDai
  //   var aTokenBalance = await aToken.balanceOf.call(hodlFactory.address);
  //   aTokenBalance = aTokenBalance * 10000000000;
  //   assert.equal(web3.utils.toWei('5000', 'ether'), aTokenBalance);
  //   // withdraw interest and check user has 10 dai interest sent to them
  //   await hodlFactory.withdrawInterest(0);
  //   var daiBalance = await cash.balanceOf(user);
  //   var difference = daiBalance - web3.utils.toWei('10', 'ether');
  //   assert.isBelow(difference/daiBalance,0.001);
  //   // check contract still has 100 dai left
  //   var daiBalance = await cash.balanceOf(aToken.address);
  //   var difference = daiBalance - web3.utils.toWei('100', 'ether');
  //   assert.isBelow(difference/daiBalance,0.001);
  //   // check hdolFactory has 5000 cDai less 9%
  //   var aTokenBalance = await aToken.balanceOf.call(hodlFactory.address);
  //   aTokenBalance = aTokenBalance * 10000000000;
  //   var difference = aTokenBalance - (web3.utils.toWei('5000', 'ether') * 100 / 110);
  //   assert.isBelow(difference/aTokenBalance,0.001);
  // });
});
