pragma solidity >=0.4.21 <0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title Dai contract interface
/// @notice Various cash functions
interface Cash 
{
    function approve(address _spender, uint _amount) external returns (bool);
    function balanceOf(address _ownesr) external view returns (uint);
    function transfer(address _to, uint _amount) external returns (bool);
}

interface IRToken
{
    function mint(uint256 mintAmount) external returns (bool);
    function balanceOf(address _user) external view returns(uint);
    function payInterest(address owner) external returns (bool);
    function interestPayableOf(address owner) external view returns (uint256 amount);
    function redeem(uint256 redeemTokens) external returns (bool);
}

contract CharityHodlFactory is ERC721Full {

    using SafeMath for uint;

    IRToken rToken;
    Cash underlying;

    address public cashAddress;

    constructor(address _cashAddress, address _RTokenAddress) ERC721Full("HodlFactory", "rHODL") public { 
        rToken = IRToken(_RTokenAddress); 
        underlying = Cash(_cashAddress);
        cashAddress = _cashAddress;
    }

    uint public hodlCount = 0;
    uint public averageTimeLastWithdrawn = 0;
    uint constant public oneHundredDai = 10**20; 
    uint public testingVariableA = 0;
    uint public testingVariableB = 0;
    uint public testingVariableC = 0;

     struct hodl {
        uint purchaseTime;
        uint interestLastWithdrawnTime;
        address interestRecipient;
    }

    mapping (uint => hodl) public hodlTracker; 

    event stfu(uint indexed stfu);

    function getHodlOwner(uint _hodlId) external view returns (address) {
        return ownerOf(_hodlId);
    }

    function getHodlPurchaseTime(uint _hodlId) external view returns (uint) {
        return hodlTracker[_hodlId].purchaseTime;
    }

    function createHodl() public {
        // UPDATE VARIABLES
        hodlTracker[hodlCount].purchaseTime = now;
        hodlTracker[hodlCount].interestLastWithdrawnTime = now;
        averageTimeLastWithdrawn = ((averageTimeLastWithdrawn.mul(hodlCount)).add(now)).div(hodlCount.add(1));
        // SWAP DAI FOR rDAI 
        // I need to transfer Dai to the contract seperately, annoyingly 
        underlying.approve(address(rToken), oneHundredDai);
        assert(rToken.mint(oneHundredDai)); 
        // // GENERATE NFT
        _mint(msg.sender, hodlCount);
        hodlCount = hodlCount.add(1);
    } 

    function getInterestAvailableToWithdrawView(uint _hodlId) public view returns (uint) {
        uint _totalRdaiBalance = rToken.balanceOf(address(this)) + rToken.interestPayableOf(address(this)); 
        uint _totalDaiBalance = hodlCount.mul(oneHundredDai);
        uint _totalInterestAvailable = _totalRdaiBalance.sub(_totalDaiBalance);
        uint _numerator = _totalInterestAvailable.mul(now.sub(hodlTracker[_hodlId].interestLastWithdrawnTime));
        uint _denominator = (now.sub(averageTimeLastWithdrawn)).mul(hodlCount);
        return (_numerator.div(_denominator));
    }

    //only needed for kovan, because interestPayableOf does not work on kovan
    function getInterestAvailableToWithdraw(uint _hodlId) public returns (uint) {
        assert(rToken.payInterest(address(this)));
        uint _totalRdaiBalance = rToken.balanceOf(address(this)); 
        uint _totalDaiBalance = hodlCount.mul(oneHundredDai);
        uint _totalInterestAvailable = _totalRdaiBalance.sub(_totalDaiBalance);
        uint _numerator = _totalInterestAvailable.mul(now.sub(hodlTracker[_hodlId].interestLastWithdrawnTime));
        uint _denominator = (now.sub(averageTimeLastWithdrawn)).mul(hodlCount);
        return (_numerator.div(_denominator));
    }

    function withdrawInterest(uint _hodlId) public {
        uint _interestToWithdraw = getInterestAvailableToWithdraw(_hodlId);
        // update variables
        uint _sumOfLastWithdrawTimes = averageTimeLastWithdrawn.mul(hodlCount);
        uint _sumOfLastWithdrawTimesUpdated = _sumOfLastWithdrawTimes.add(now).sub(hodlTracker[_hodlId].interestLastWithdrawnTime);
        averageTimeLastWithdrawn = _sumOfLastWithdrawTimesUpdated.div(hodlCount);
        hodlTracker[_hodlId].interestLastWithdrawnTime = now;
        // external calls
        assert(rToken.redeem(_interestToWithdraw));
        underlying.transfer(ownerOf(_hodlId), _interestToWithdraw);
    }

    function destroyHodl(uint _hodlId) public {
        require (ownerOf(_hodlId) == msg.sender, "Not owner");
        // require (hodlTracker[_hodlId].purchaseTime.add(3600) < now, "HODL must be owned for 1 hour");
        withdrawInterest(_hodlId);
        // update averageTimeLastWithdrawn
        if (hodlCount > 1) {
            averageTimeLastWithdrawn = ((averageTimeLastWithdrawn.mul(hodlCount)).sub(hodlTracker[_hodlId].interestLastWithdrawnTime)).div(hodlCount.sub(1));
        } else {
            averageTimeLastWithdrawn = 0;
        }
        // external calls
        rToken.redeem(oneHundredDai);
        underlying.transfer(ownerOf(_hodlId), oneHundredDai);
        // remove HODL
        hodlCount = hodlCount.sub(1);
        _burn(_hodlId);
    }

}
