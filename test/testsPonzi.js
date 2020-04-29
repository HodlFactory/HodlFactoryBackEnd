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
const PonziHodlFactory = artifacts.require("PonziHodlFactory");

contract('PonziHodlFactoryTests', (accounts) => {

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
    hodlFactory = await PonziHodlFactory.new(cash.address, aToken.address, aToken.address, aToken.address);
  });

  it('createHodl', async () => {
    await hodlFactory.createHodl("Andrew");
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

  it('check players my tier or below', async () => {
    //ten hodls
    var i;
    for (i = 0; i < 10; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    // check no players my tier or below
    var playersEqualOrBelow = await hodlFactory.getPlayersMyTierOrBelow.call(0);
    assert.equal(playersEqualOrBelow.toString(),10);
    // new tier
    for (i = 0; i < 6; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    var playersEqualOrBelow = await hodlFactory.getPlayersMyTierOrBelow.call(5);
    assert.equal(playersEqualOrBelow.toString(),10);
    var playersEqualOrBelow = await hodlFactory.getPlayersMyTierOrBelow.call(12);
    assert.equal(playersEqualOrBelow.toString(),16);
    // check that there is no interest allocated to any of them

  });

  //this one takes ages
  it('create lots of Hodls, check tiers', async () => {
    var i;
    for (i = 0; i < 10; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    // check tier count
    var tierCount = await hodlFactory.tierCount.call();
    assert.equal(tierCount,0);
    // check hodl tier
    var hodlTierStruct = await hodlFactory.hodlProperties.call(9);
    var hodlTier = hodlTierStruct[1];
    assert.equal(hodlTier,0);
    // one more hodl
    // check tier count
    await hodlFactory.createHodl("Andrew");
    tierCount = await hodlFactory.tierCount.call();
    assert.equal(tierCount,1);
    // check hodl tier
    var hodlTierStruct = await hodlFactory.hodlProperties.call(10);
    var hodlTier = hodlTierStruct[1];
    assert.equal(hodlTier,1);
    // make more hodls
    for (i = 0; i < 35; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    tierCount = await hodlFactory.tierCount.call();
    assert.equal(tierCount,3);
    await hodlFactory.createHodl("Andrew");
    tierCount = await hodlFactory.tierCount.call();
    assert.equal(tierCount,4);
    // check size of tiers 
    var tierSizeStruct = await hodlFactory.tierProperties.call(4);
    var tierSize = tierSizeStruct[0];
    assert.equal(tierSize,14);
    // check number of hodls
    await hodlFactory.createHodl("Andrew");
    await hodlFactory.createHodl("Andrew");
    var hodlCountStruct = await hodlFactory.tierProperties.call(4);
    var hodlCount = hodlCountStruct[1];
    assert.equal(hodlCount,3);
  });

  it('create second Hodl, check averagePurchaseTime', async () => {
    // hodl1
    purchaseTime1 = await time.latest();
    await hodlFactory.createHodl("Andrew");
    var puchaseTimeStruct = await hodlFactory.tierProperties.call(0);
    var averagePurchaseTime = puchaseTimeStruct[2];
    var difference = Math.abs(purchaseTime1.toString() - averagePurchaseTime.toString());
    assert.isBelow(difference/purchaseTime1, 0.0001);
    // hodl2
    await time.increase(time.duration.weeks(1));
    purchaseTime2 = await time.latest();
    await hodlFactory.createHodl("Andrew");
    var puchaseTimeStruct = await hodlFactory.tierProperties.call(0);
    var averagePurchaseTime = puchaseTimeStruct[2];
    var averagePurchaseTimeShouldBe = (purchaseTime1.toNumber() + purchaseTime2.toNumber())/2;
    var difference = Math.abs(averagePurchaseTime.toString() - averagePurchaseTimeShouldBe.toString());
    assert.isBelow(difference/averagePurchaseTime, 0.0001);
  });

 it('check getTierInterestAccrued', async () => {
    //ten hodls
    var i;
    for (i = 0; i < 10; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    await aToken.generate10PercentInterest(hodlFactory.address);
    await time.increase(time.duration.days(1));
    // check 100 dai interest tier 1
    var interestAvailable = await hodlFactory.getTierInterestAccrued.call(0);
    assert.equal(interestAvailable.toString(),web3.utils.toWei('100', 'ether'));
    // another round
    for (i = 0; i < 11; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    await time.increase(time.duration.days(1));
    // now have 21 hodls, still 100 dai interest. it should be split 2 thirds for first tier, 1 third for second.
    // tier 0 always zero interest
    var interestAvailable = await hodlFactory.getTierInterestAccrued.call(0);
    var interestAvailableShouldBe = (web3.utils.toWei('100', 'ether')/31)*20;
    var difference = Math.abs(interestAvailable-interestAvailableShouldBe);
    assert.isBelow(difference/interestAvailable,0.0001);
    var interestAvailable = await hodlFactory.getTierInterestAccrued.call(1);
    var interestAvailableShouldBe = (web3.utils.toWei('100', 'ether')/31)*11;
    var difference = Math.abs(interestAvailable-interestAvailableShouldBe);
    assert.isBelow(difference/interestAvailable,0.0001);
    var interestAvailable = await hodlFactory.getTierInterestAccrued.call(1);
    var interestAvailableShouldBe = (web3.utils.toWei('100', 'ether')/31)*11;
    var difference = Math.abs(interestAvailable-interestAvailableShouldBe);
    assert.isBelow(difference/interestAvailable,0.0001);
    // check interest for hodl that does not exist is 0
    var interestAvailable = await hodlFactory.getTierInterestAccrued.call(2);
    assert.equal(interestAvailable,0);
    // pritnt 5 more for third tier. 
    for (i = 0; i < 5; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    await time.increase(time.duration.days(1));
    var interestAvailable = await hodlFactory.getTierInterestAccrued.call(0);
    var interestAvailableShouldBe = (web3.utils.toWei('100', 'ether')/57)*30;
    var difference = Math.abs(interestAvailable-interestAvailableShouldBe);
    assert.isBelow(difference/interestAvailable,0.0001);
    var interestAvailable = await hodlFactory.getTierInterestAccrued.call(1);
    var interestAvailableShouldBe = (web3.utils.toWei('100', 'ether')/57)*22;
    var difference = Math.abs(interestAvailable-interestAvailableShouldBe);
    assert.isBelow(difference/interestAvailable,0.0001);
    var interestAvailable = await hodlFactory.getTierInterestAccrued.call(2);
    var interestAvailableShouldBe = (web3.utils.toWei('100', 'ether')/57)*5;
    var difference = Math.abs(interestAvailable-interestAvailableShouldBe);
    assert.isBelow(difference/interestAvailable,0.0001)
  });

 it('check getInterestAvailableToWithdrawView', async () => {
    //ten hodls
    var i;
    for (i = 0; i < 10; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    await aToken.generate10PercentInterest(hodlFactory.address);
    await time.increase(time.duration.days(1));
    // check 0 dai interest each
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdrawView.call(0);
    assert.equal(interestAvailable,0);
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdrawView.call(9);
    assert.equal(interestAvailable,0);
    await shouldFail.reverting.withMessage(hodlFactory.getInterestAvailableToWithdrawView.call(10), "revert ERC721: owner query for nonexistent token");
    // another round
    for (i = 0; i < 11; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    var interestAvailableTier1 = await hodlFactory.getTierInterestAccrued.call(1);
    // tier 0 hodl interest:
    var interestAvailableShouldBe = (interestAvailableTier1/10);
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdrawView.call(0);
    var difference = Math.abs(interestAvailable-interestAvailableShouldBe);
    assert.isBelow(difference/interestAvailable,0.0001);
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdrawView.call(9);
    var difference = Math.abs(interestAvailable-interestAvailableShouldBe);
    assert.isBelow(difference/interestAvailable,0.0001);
    // tier 1 hodl interest, zero cos no tier 2
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdrawView.call(10);
    assert.equal(interestAvailable.toString(),0);
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdrawView.call(20);
    assert.equal(interestAvailable.toString(),0);
    // pritnt 5 more for third tier. 
    for (i = 0; i < 5; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    await time.increase(time.duration.days(1));
    var interestAvailableTier0 = await hodlFactory.getTierInterestAccrued.call(0);
    var interestAvailableTier1 = await hodlFactory.getTierInterestAccrued.call(1);
    var interestAvailableTier2 = await hodlFactory.getTierInterestAccrued.call(2);
    // tier 0 hodl interest:
    var interestAvailableShouldBe = (interestAvailableTier1/10) + (interestAvailableTier2/21);
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdrawView.call(0);
    var difference = Math.abs(interestAvailable-interestAvailableShouldBe);
    assert.isBelow(difference/interestAvailable,0.0001);
    var interestAvailableShouldBe = (interestAvailableTier1/10) + (interestAvailableTier2/21);
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdrawView.call(9);
    var difference = Math.abs(interestAvailable-interestAvailableShouldBe);
    assert.isBelow(difference/interestAvailable,0.0001);
    // tier 1 hodl interest:
    var interestAvailableShouldBe = (interestAvailableTier2/21);
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdrawView.call(10);
    var difference = Math.abs(interestAvailable-interestAvailableShouldBe);
    assert.isBelow(difference/interestAvailable,0.0001);
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdrawView.call(20);
    var difference = Math.abs(interestAvailable-interestAvailableShouldBe);
    assert.isBelow(difference/interestAvailable,0.0001);
    // tier 2 hodl interest, zero cos no tier 2
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdrawView.call(21);
    assert.equal(interestAvailable.toString(),0);
    var interestAvailable = await hodlFactory.getInterestAvailableToWithdrawView.call(25);
    assert.equal(interestAvailable.toString(),0);
  });

  it('check destroyHodl, one HODL', async () => {
    user = user0;
    await hodlFactory.createHodl("Andrew");
    await time.increase(time.duration.days(1)); 
    await aToken.generate10PercentInterest(hodlFactory.address);
    await hodlFactory.destroyHodl(0);
    var totalReceipt = await cash.balanceOf.call(user);
    var interestReceipt = totalReceipt - web3.utils.toWei('100', 'ether');
    assert.equal(interestReceipt,0)
  });

   it('various destroy and create', async () => {
    //two rounds
    var i;
    for (i = 0; i < 10; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    await aToken.generate10PercentInterest(hodlFactory.address);
    await time.increase(time.duration.days(1));
    // another round
    for (i = 0; i < 11; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    await time.increase(time.duration.days(1));
    // now have 21 hodls, still 100 dai interest. 
    // check tier
    // check individual interest
    await hodlFactory.destroyHodl(0);
    var totalReceipt = await cash.balanceOf.call(user);
    var interestReceipt = totalReceipt - web3.utils.toWei('100', 'ether');
    assert.isAbove(interestReceipt,0)
    //
    await cash.resetBalance(user);
    await hodlFactory.destroyHodl(1);
    var totalReceipt = await cash.balanceOf.call(user);
    var interestReceipt = totalReceipt - web3.utils.toWei('100', 'ether');
    assert.isAbove(interestReceipt,0)
    //
    await cash.resetBalance(user);
    await hodlFactory.destroyHodl(5);
    var totalReceipt = await cash.balanceOf.call(user);
    var interestReceipt = totalReceipt - web3.utils.toWei('100', 'ether');
    assert.isAbove(interestReceipt,2)
    //
    await cash.resetBalance(user);
    await hodlFactory.destroyHodl(15);
    var totalReceipt = await cash.balanceOf.call(user);
    var interestReceipt = totalReceipt - web3.utils.toWei('100', 'ether');
    assert.equal(interestReceipt,0)
    //top up next tier
    for (i = 0; i < 12; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    await cash.resetBalance(user);
    await hodlFactory.destroyHodl(3);
    var totalReceipt = await cash.balanceOf.call(user);
    var interestReceipt = totalReceipt - web3.utils.toWei('100', 'ether');
    assert.isAbove(interestReceipt,0)
    //
    await cash.resetBalance(user);
    await hodlFactory.destroyHodl(14);
    var totalReceipt = await cash.balanceOf.call(user);
    var interestReceipt = totalReceipt - web3.utils.toWei('100', 'ether');
    assert.isAbove(interestReceipt,0)
    //
    await cash.resetBalance(user);
    await hodlFactory.destroyHodl(16);
    var totalReceipt = await cash.balanceOf.call(user);
    var interestReceipt = totalReceipt - web3.utils.toWei('100', 'ether');
    assert.isAbove(interestReceipt,2)
    //
    await cash.resetBalance(user);
    await hodlFactory.destroyHodl(25);
    var totalReceipt = await cash.balanceOf.call(user);
    var interestReceipt = totalReceipt - web3.utils.toWei('100', 'ether');
    assert.equal(interestReceipt,0)
  });


  it('test withdraw', async () => {
    //two rounds
    var i;
    for (i = 0; i < 10; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    await aToken.generate10PercentInterest(hodlFactory.address);
    await time.increase(time.duration.days(1));
    // another round
    for (i = 0; i < 11; i++) {
      await hodlFactory.createHodl("Andrew");
    }
    await time.increase(time.duration.days(1));
    // now have 21 hodls, still 100 dai interest. 
    // check tier
    // check individual interest
    await hodlFactory.withdrawInterest(0);
    var totalReceipt = await cash.balanceOf.call(user);
    var totalReceipt2 = totalReceipt - web3.utils.toWei('0', 'ether')
    assert.isAbove(totalReceipt2,0)
    // try again, should be zero
    await cash.resetBalance(user);
    await hodlFactory.withdrawInterest(0);
    var totalReceipt = await cash.balanceOf.call(user);
    var totalReceipt2 = totalReceipt - web3.utils.toWei('0', 'ether')
    assert.equal(totalReceipt2,0)
    // add more interest, should be some now
    await cash.resetBalance(user);
    await aToken.generate10PercentInterest(hodlFactory.address);
    await hodlFactory.withdrawInterest(0);
    var totalReceipt = await cash.balanceOf.call(user);
    var totalReceipt2 = totalReceipt - web3.utils.toWei('0', 'ether')
    assert.isAbove(totalReceipt2,0)
    await cash.resetBalance(user);
    await hodlFactory.withdrawInterest(0);
    var totalReceipt = await cash.balanceOf.call(user);
    var totalReceipt2 = totalReceipt - web3.utils.toWei('0', 'ether')
    assert.equal(totalReceipt2,0)
    // different hodl
    await hodlFactory.withdrawInterest(1);
    var totalReceipt = await cash.balanceOf.call(user);
    var totalReceipt2 = totalReceipt - web3.utils.toWei('0', 'ether')
    assert.isAbove(totalReceipt2,0)
    // try again, should be zero
    await cash.resetBalance(user);
    await hodlFactory.withdrawInterest(1);
    var totalReceipt = await cash.balanceOf.call(user);
    var totalReceipt2 = totalReceipt - web3.utils.toWei('0', 'ether')
    assert.equal(totalReceipt2,0)
    // destroy should be 100
    await cash.resetBalance(user);
    await hodlFactory.destroyHodl(1);
    var totalReceipt = await cash.balanceOf.call(user);
    var interestReceipt = totalReceipt - web3.utils.toWei('100', 'ether');
    assert.equal(interestReceipt,0)
  });

});
