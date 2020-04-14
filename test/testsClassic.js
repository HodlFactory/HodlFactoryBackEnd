const {
  BN,
  shouldFail,
  ether,
  expectEvent,
  balance,
  time
} = require('openzeppelin-test-helpers');

const CashMockup = artifacts.require("CashMockup");
const aTokenMockup = artifacts.require("aTokenMockup");
const ClassicHodlFactory = artifacts.require("ClassicHodlFactory");

contract('ClassicHodlFactoryTests', (accounts) => {

  user = accounts[0];
  user0 = accounts[0];
  user1 = accounts[1];
  user2 = accounts[2];
  user3 = accounts[3];
  user4 = accounts[4];
  user5 = accounts[5];
  user6 = accounts[6];
  user7 = accounts[7];
  user8 = accounts[8];

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

  it('create second Hodl, check averageTimeLastWithdrawn', async () => {
    // hodl1
    purchaseTime1 = await time.latest();
    await hodlFactory.createHodl();
    var averagePurchaseTime = await hodlFactory.averageTimeLastWithdrawn.call();
    assert.equal(purchaseTime1.toString(),averagePurchaseTime.toString());
    // hodl2
    await time.increase(time.duration.weeks(1));
    purchaseTime2 = await time.latest();
    await hodlFactory.createHodl();
    averagePurchaseTime = await hodlFactory.averageTimeLastWithdrawn.call();
    var averagePurchaseTimeShouldBe = (purchaseTime1.toNumber() + purchaseTime2.toNumber())/2;
    assert.equal(averagePurchaseTimeShouldBe,averagePurchaseTime.toNumber());
  });

  it('check getInterestAvailableToWithdraw, single HODL', async () => {
    await hodlFactory.createHodl();
    await aToken.generate10PercentInterest(hodlFactory.address);
    await time.increase(time.duration.days(1)); // to avoid multiply by zero when doing now - purchase time
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdraw.call(0);
    var interestAvailableShouldBe = new BN(web3.utils.toWei('10', 'ether'));
    assert.equal(interestAvailable.toString(),interestAvailableShouldBe.toString());
  });

  it('check getInterestAvailableToWithdraw, two HODLs', async () => {
    await hodlFactory.createHodl();
    await time.increase(time.duration.days(1)); 
    await hodlFactory.createHodl();
    await time.increase(time.duration.days(2));
    await aToken.generate10PercentInterest(hodlFactory.address);
    //10 units of time, 20 dai interest, 0th = 3/5 = 12; 1st = 2/5 = 8
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdraw.call(0);
    var interestAvailableShouldBe = new BN(web3.utils.toWei('12', 'ether'));
    assert.equal(interestAvailable.toString(),interestAvailableShouldBe.toString());
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdraw.call(1);
    var interestAvailableShouldBe = new BN(web3.utils.toWei('8', 'ether'));
    assert.equal(interestAvailable.toString(),interestAvailableShouldBe.toString());
  });

  it('check withdrawInterest, single HODL', async () => {
    user = user0;
    await hodlFactory.createHodl();
    await aToken.generate10PercentInterest(hodlFactory.address);
    await time.increase(time.duration.days(1)); // to avoid multiply by zero when doing now - purchase time
    await hodlFactory.withdrawInterest(0);
    var interestWithdrawn = await cash.balanceOf.call(user);
    var interestShouldBe = new BN(web3.utils.toWei('10', 'ether'));
    assert.equal(interestWithdrawn.toString(),interestShouldBe.toString());
  });

  it('check withdrawInterest, two HODLs', async () => {
    await hodlFactory.createHodl({ from: user0 });
    var hodlOwner = await hodlFactory.ownerOf.call(0);
    assert.equal(user0, hodlOwner);
    await time.increase(time.duration.days(1)); 
    await hodlFactory.createHodl({ from: user1 });
    var hodlOwner = await hodlFactory.ownerOf.call(1);
    assert.equal(user1, hodlOwner);
    await time.increase(time.duration.days(2));
    await aToken.generate10PercentInterest(hodlFactory.address);
    await hodlFactory.withdrawInterest(0);
    var interestWithdrawn = await cash.balanceOf.call(user0);
    var interestShouldBe = new BN(web3.utils.toWei('12', 'ether'));
    assert.equal(interestWithdrawn.toString(),interestShouldBe.toString());
    await hodlFactory.withdrawInterest(1);
    var interestWithdrawn = await cash.balanceOf.call(user1);
    var interestShouldBe = new BN(web3.utils.toWei('8', 'ether'));
    assert.equal(interestWithdrawn.toString(),interestShouldBe.toString());
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
