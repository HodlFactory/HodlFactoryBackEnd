pragma solidity >=0.4.21 <0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title Dai contract interface
/// @notice Various cash functions
interface Cash 
{
    function approve(address _spender, uint _amount) external returns (bool);
    function balanceOf(address _ownesr) external view returns (uint);
    function mint(uint256) external;
    function transfer(address _to, uint _amount) external returns (bool);
}

interface IaToken 
{
    function balanceOf(address _user) external view returns(uint);
    function redeem(uint256 _amount) external;
}

interface IAaveLendingPool 
{
    function deposit( address _reserve, uint256 _amount, uint16 _referralCode) external;
}

interface IAaveLendingPoolCore {}

contract ClassicHodlFactory is ERC721Full {

    using SafeMath for uint;

    Cash underlying;
    IaToken aToken;
    IAaveLendingPool aaveLendingPool;
    IAaveLendingPoolCore aaveLendingPoolCore;

    constructor(address _cashAddress, address _aTokenAddress, address _aaveLpAddress, address _aaveLpcoreAddress ) ERC721Full("HodlFactory", "HODL") public { 
        underlying = Cash(_cashAddress);
        aToken = IaToken(_aTokenAddress); 
        aaveLendingPool = IAaveLendingPool(_aaveLpAddress); 
        aaveLendingPoolCore = IAaveLendingPoolCore(_aaveLpcoreAddress); 
    }

    uint public hodlCount = 0;
    uint public averageTimeLastWithdrawn = 0;
    uint constant public oneHundredDai = 10**20;
    uint public testingVariableA = 69;
    uint public testingVariableB = 0;
    uint public testingVariableC = 0;
    uint public testingVariableD = 0;
    uint public testingVariableE = 0;

     struct hodl {
        uint purchaseTime;
        uint interestLastWithdrawnTime;
    }

    mapping (uint => hodl) public hodlTracker; 

    event stfu(uint indexed stfu);

    function getHodlPurchaseTime(uint _hodlId) external view returns (uint) {
        return hodlTracker[_hodlId].purchaseTime;
    }

    function getAdaiBalance() public view returns (uint) {
        return(aToken.balanceOf(address(this)));
    }

    function createHodl() public {
        // UPDATE VARIABLES
        hodlTracker[hodlCount].purchaseTime = now;
        hodlTracker[hodlCount].interestLastWithdrawnTime = now;
        averageTimeLastWithdrawn = ((averageTimeLastWithdrawn.mul(hodlCount)).add(now)).div(hodlCount.add(1));
         // SWAP DAI FOR aDAI
        underlying.mint(oneHundredDai);
        underlying.approve(address(aaveLendingPoolCore), oneHundredDai);
        aaveLendingPool.deposit(address(underlying), oneHundredDai, 0);
        // // GENERATE NFT
        _mint(msg.sender, hodlCount);
        hodlCount = hodlCount.add(1);
    } 

    function getInterestAvailableToWithdraw(uint _hodlId) public view returns (uint) {
        uint _totalAdaiBalance = aToken.balanceOf(address(this)); 
        uint _totalDaiBalance = hodlCount.mul(oneHundredDai);
        uint _totalInterestAvailable = _totalAdaiBalance.sub(_totalDaiBalance);
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
        aToken.redeem(_interestToWithdraw);
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
        aToken.redeem(oneHundredDai);
        underlying.transfer(ownerOf(_hodlId), oneHundredDai);
        // remove HODL
        hodlCount = hodlCount.sub(1);
        _burn(_hodlId);
    }

}
