pragma solidity >=0.4.21 <0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@nomiclabs/buidler/console.sol";

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
    uint public latestHodlId = 0;
    uint public averageTimeLastWithdrawn = 0;
    uint constant public oneHundredDai = 10**20;

     struct hodl {
        uint purchaseTime;
        uint interestLastWithdrawnTime;
        string name;
    }

    mapping (uint => hodl) public hodlProperties; 
    mapping (address => uint[]) hodlOwnerTracker;
    mapping (address => uint[]) hodlsDeletedTracker;

    // event stfu(uint indexed stfu);

    function getHodlPurchaseTime(uint _hodlId) external view returns (uint) {
        return hodlProperties[_hodlId].purchaseTime;
    }

    function getHodlName(uint _hodlId) external view returns (string memory) {
        return hodlProperties[_hodlId].name;
    }

    function getAdaiBalance() public view returns (uint) {
        return(aToken.balanceOf(address(this)));
    }

    function getHodlsOwned() public view returns(uint[] memory) {
        return(hodlOwnerTracker[msg.sender]);
    }

    function getHodlsDeleted() public view returns(uint[] memory) {
        return(hodlsDeletedTracker[msg.sender]);
    }

    function createHodl(string memory _name) public {
        // UPDATE VARIABLES
        hodlOwnerTracker[msg.sender].push(latestHodlId);
        hodlProperties[latestHodlId].purchaseTime = now;
        hodlProperties[latestHodlId].interestLastWithdrawnTime = now;
        hodlProperties[latestHodlId].name = _name;
        averageTimeLastWithdrawn = ((averageTimeLastWithdrawn.mul(hodlCount)).add(now)).div(hodlCount.add(1));
         // SWAP DAI FOR aDAI
        underlying.mint(oneHundredDai);
        underlying.approve(address(aaveLendingPoolCore), oneHundredDai);
        aaveLendingPool.deposit(address(underlying), oneHundredDai, 0);
        // // GENERATE NFT
        _mint(msg.sender, latestHodlId);
        hodlCount = hodlCount.add(1);  
        latestHodlId = latestHodlId.add(1);
    } 

    function getInterestAvailableToWithdraw(uint _hodlId) public view returns (uint) {
        uint _totalAdaiBalance = aToken.balanceOf(address(this)); 
        uint _totalDaiBalance = hodlCount.mul(oneHundredDai);
        uint _totalInterestAvailable = _totalAdaiBalance.sub(_totalDaiBalance);
        uint _numerator = _totalInterestAvailable.mul(now.sub(hodlProperties[_hodlId].interestLastWithdrawnTime));
        uint _denominator = (now.sub(averageTimeLastWithdrawn)).mul(hodlCount);
        return (_numerator.div(_denominator));
    }

    function withdrawInterest(uint _hodlId) public {
        uint _interestToWithdraw = getInterestAvailableToWithdraw(_hodlId);
        // update variables
        uint _sumOfLastWithdrawTimes = averageTimeLastWithdrawn.mul(hodlCount);
        uint _sumOfLastWithdrawTimesUpdated = _sumOfLastWithdrawTimes.add(now).sub(hodlProperties[_hodlId].interestLastWithdrawnTime);
        averageTimeLastWithdrawn = _sumOfLastWithdrawTimesUpdated.div(hodlCount);
        hodlProperties[_hodlId].interestLastWithdrawnTime = now;
        // external calls
        aToken.redeem(_interestToWithdraw);
        underlying.transfer(ownerOf(_hodlId), _interestToWithdraw);
    }

    function destroyHodl(uint _hodlId) public {
        require (ownerOf(_hodlId) == msg.sender, "Not owner");
        // require (hodlProperties[_hodlId].purchaseTime.add(3600) < now, "HODL must be owned for 1 hour");
        withdrawInterest(_hodlId);
        // update averageTimeLastWithdrawn
        if (hodlCount > 1) {
            averageTimeLastWithdrawn = ((averageTimeLastWithdrawn.mul(hodlCount)).sub(hodlProperties[_hodlId].interestLastWithdrawnTime)).div(hodlCount.sub(1));
        } else {
            averageTimeLastWithdrawn = 0;
        }
        // external calls
        aToken.redeem(oneHundredDai);
        underlying.transfer(ownerOf(_hodlId), oneHundredDai);
        // remove HODL
        hodlCount = hodlCount.sub(1);
        _burn(_hodlId);
        hodlsDeletedTracker[msg.sender].push(_hodlId);
    }

    // transfer override, needs work before mainnet
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        hodlsDeletedTracker[from].push(tokenId);
        hodlOwnerTracker[to].push(tokenId);
        _transferFrom(from, to, tokenId);
    }

}
