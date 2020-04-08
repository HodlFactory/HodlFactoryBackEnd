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
    function balanceOf(address) view external;
    function getMaximumHatID() external view returns (uint256 hatID);    
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
    uint constant public oneHundredDai = 10**18; //this is actually 1 Dai for now
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

    function buyHodl() public {
        // UPDATE VARIABLES
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

    function getInterestAvailableToWithdraw(uint _hodlId) public view returns (uint) {
        uint _totalRdaiBalance = rToken.interestPayableOf(address(this));
        uint _totalDaiBalance = hodlCount.mul(oneHundredDai);
        assert (_totalRdaiBalance > _totalDaiBalance);
        uint _totalInterestAvailable = _totalRdaiBalance.sub(_totalDaiBalance);
        uint _numerator = _totalInterestAvailable.mul(now.sub(hodlTracker[_hodlId].interestLastWithdrawnTime));
        uint _denominator = (now.sub(averageTimeLastWithdrawn)).mul(hodlCount);
        return (_numerator.div(_denominator));
    }

    function withdrawInterest(uint _hodlId) public {
        // update variables
        uint _sumOfLastWithdrawTimes = averageTimeLastWithdrawn.mul(hodlCount);
        uint _sumOfLastWithdrawTimesUpdated = _sumOfLastWithdrawTimes.add(now).sub(hodlTracker[_hodlId].interestLastWithdrawnTime);
        averageTimeLastWithdrawn = _sumOfLastWithdrawTimesUpdated.div(hodlCount);
        hodlTracker[_hodlId].interestLastWithdrawnTime = now;
        // external calls
        uint _interestToWithdraw = getInterestAvailableToWithdraw(_hodlId);
        assert(rToken.redeem(_interestToWithdraw));
        underlying.transfer(hodlTracker[_hodlId].interestRecipient, _interestToWithdraw);
    }

    function destroyHodl(uint _hodlId) public {
        require (ownerOf(_hodlId) == msg.sender, "Not owner");
        require (hodlTracker[_hodlId].purchaseTime.add(3600) < now, "HODL must be owned for 1 hour");
        // update variables
        averageTimeLastWithdrawn = ((averageTimeLastWithdrawn.mul(hodlCount)).sub(hodlTracker[_hodlId].interestLastWithdrawnTime)).div(hodlCount.sub(1));
        hodlCount = hodlCount.sub(1);
        // external calls
        _burn(_hodlId);
        withdrawInterest(_hodlId);
        rToken.redeem(oneHundredDai);
        underlying.transfer(ownerOf(_hodlId), oneHundredDai);
    }

}
