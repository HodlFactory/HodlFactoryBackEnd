const {
  BN,
  shouldFail,
  ether,
  expectEvent,
  balance,
  time
} = require('openzeppelin-test-helpers');

const CashMockup = artifacts.require("CashMockup");
const rTokenMockup = artifacts.require("rTokenMockup");
const CharityHodlFactory = artifacts.require("CharityHodlFactory");

contract('CharityHodlFactoryTests', (accounts) => {

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
    rToken = await rTokenMockup.new(cash.address);
    hodlFactory = await CharityHodlFactory.new(cash.address, rToken.address);
  });

  it('createHodl', async () => {
    await hodlFactory.createHodl("Andrew",user);
    var hodlCount = await hodlFactory.hodlCount.call();
    assert.equal(hodlCount,1);
    // check that 100 Dai allocated
    var daiBalance = await cash.balanceOf.call(rToken.address);
    assert.equal(web3.utils.toWei('100', 'ether'), daiBalance.toString());
    // check that 100 aDai allocated
    var rTokenBalance = await rToken.balanceOf.call(hodlFactory.address);
    assert.equal(web3.utils.toWei('100', 'ether'), rTokenBalance);
    // check that hodlTracker is good
    var hodlOwner = await hodlFactory.ownerOf.call(0);
    assert.equal(user, hodlOwner);
  });

  it('create second Hodl, check averageTimeLastWithdrawn', async () => {
    // hodl1
    purchaseTime1 = await time.latest();
    await hodlFactory.createHodl("Andrew",user);
    var averagePurchaseTime = await hodlFactory.averageTimeLastWithdrawn.call();
    var difference = Math.abs(purchaseTime1.toString() - averagePurchaseTime.toString());
    assert.isBelow(difference/purchaseTime1, 0.0001);
    // hodl2
    await time.increase(time.duration.weeks(1));
    purchaseTime2 = await time.latest();
    await hodlFactory.createHodl("Andrew",user);
    averagePurchaseTime = await hodlFactory.averageTimeLastWithdrawn.call();
    var averagePurchaseTimeShouldBe = (purchaseTime1.toNumber() + purchaseTime2.toNumber())/2;
    var difference = Math.abs(averagePurchaseTime.toString() - averagePurchaseTimeShouldBe.toString());
    assert.isBelow(difference/averagePurchaseTime, 0.0001);
  });

  it('check getInterestAvailableToWithdraw, single HODL', async () => {
    await hodlFactory.createHodl("Andrew",user);
    await rToken.generate10PercentInterest(hodlFactory.address);
    await time.increase(time.duration.days(1)); // to avoid multiply by zero when doing now - purchase time
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdraw.call(0);
    var interestAvailableShouldBe = new BN(web3.utils.toWei('10', 'ether'));
    assert.equal(interestAvailable.toString(),interestAvailableShouldBe.toString());
  });

  it('check getInterestAvailableToWithdraw, two HODLs', async () => {
    await hodlFactory.createHodl("Andrew",user);
    await time.increase(time.duration.days(1)); 
    await hodlFactory.createHodl("Andrew",user);
    await time.increase(time.duration.days(2));
    await rToken.generate10PercentInterest(hodlFactory.address);
    //10 units of time, 20 dai interest, 0th = 3/5 = 12; 1st = 2/5 = 8
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdraw.call(0);
    var interestAvailableShouldBe = new BN(web3.utils.toWei('12', 'ether'));
    var difference = Math.abs(interestAvailable.toString() - interestAvailableShouldBe.toString());
    assert.isBelow(difference/interestAvailable,0.0001);
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdraw.call(1);
    var interestAvailableShouldBe = new BN(web3.utils.toWei('8', 'ether'));
    var difference = Math.abs(interestAvailable.toString() - interestAvailableShouldBe.toString());
    assert.isBelow(difference/interestAvailable,0.0001);
  });

  it('check withdrawInterest, single HODL', async () => {
    user = user0;
    await hodlFactory.createHodl("Andrew",user);
    await rToken.generate10PercentInterest(hodlFactory.address);
    await time.increase(time.duration.days(1)); // to avoid multiply by zero when doing now - purchase time
    await hodlFactory.withdrawInterest(0);
    var interestWithdrawn = await cash.balanceOf.call(user);
    var interestShouldBe = new BN(web3.utils.toWei('10', 'ether'));
    assert.equal(interestWithdrawn.toString(),interestShouldBe.toString());
  });

  it('check withdrawInterest, two HODLs', async () => {
    await hodlFactory.createHodl("Andrew",user,{ from: user0 });
    var hodlOwner = await hodlFactory.ownerOf.call(0);
    assert.equal(user0, hodlOwner);
    await time.increase(time.duration.days(1)); 
    await hodlFactory.createHodl("Andrew",user1,{ from: user1 });
    var hodlOwner = await hodlFactory.ownerOf.call(1);
    assert.equal(user1, hodlOwner);
    await time.increase(time.duration.days(2));
    await rToken.generate10PercentInterest(hodlFactory.address);
    await hodlFactory.withdrawInterest(0);
    var interestWithdrawn = await cash.balanceOf.call(user0);
    var interestShouldBe = new BN(web3.utils.toWei('12', 'ether'));
    var difference = Math.abs(interestShouldBe.toString() - interestWithdrawn.toString());
    assert.isBelow(difference/interestWithdrawn,0.0001);
    await hodlFactory.withdrawInterest(1);
    var interestWithdrawn = await cash.balanceOf.call(user1);
    var interestShouldBe = new BN(web3.utils.toWei('8', 'ether'));
    var difference = Math.abs(interestShouldBe.toString() - interestWithdrawn.toString());
    assert.isBelow(difference/interestWithdrawn,0.0001);
  });

  it('check destroyHodl, one HODL', async () => {
    user = user0;
    await hodlFactory.createHodl("Andrew",user,{ from: user });
    await time.increase(time.duration.days(1)); 
    await rToken.generate10PercentInterest(hodlFactory.address);
    await hodlFactory.destroyHodl(0);
    var interestWithdrawn = await cash.balanceOf.call(user);
    var interestShouldBe = new BN(web3.utils.toWei('110', 'ether'));
    var difference = Math.abs(interestShouldBe.toString() - interestWithdrawn.toString());
    assert.isBelow(difference/interestWithdrawn,0.0001);
  });

  it('check destroyHodl, two HODLs', async () => {
    await hodlFactory.createHodl("Andrew",user,{ from: user0 });
    var hodlOwner = await hodlFactory.ownerOf.call(0);
    assert.equal(user0, hodlOwner);
    await time.increase(time.duration.days(1)); 
    await hodlFactory.createHodl("Andrew",user1,{ from: user1 });
    var hodlOwner = await hodlFactory.ownerOf.call(1);
    assert.equal(user1, hodlOwner);
    await time.increase(time.duration.days(2));
    await rToken.generate10PercentInterest(hodlFactory.address);
    await hodlFactory.destroyHodl(0,{ from: user0 });
    var interestWithdrawn = await cash.balanceOf.call(user0);
    var interestShouldBe = new BN(web3.utils.toWei('112', 'ether'));
    var difference = Math.abs(interestShouldBe.toString() - interestWithdrawn.toString());
    assert.isBelow(difference/interestWithdrawn,0.0001);
    await hodlFactory.destroyHodl(1,{ from: user1 });
    var interestWithdrawn = await cash.balanceOf.call(user1);
    var interestShouldBe = new BN(web3.utils.toWei('108', 'ether'));
    var difference = Math.abs(interestShouldBe.toString() - interestWithdrawn.toString());
    assert.isBelow(difference/interestWithdrawn,0.0001);
  });

  it('check destroyHodl then create After', async () => {
    user = user0;
    await hodlFactory.createHodl("Andrew",user);
    await time.increase(time.duration.days(1)); 
    await rToken.generate10PercentInterest(hodlFactory.address);
    await hodlFactory.destroyHodl(0);
    await hodlFactory.createHodl("Andrew",user);

  });




});
