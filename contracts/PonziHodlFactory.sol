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

contract PonziHodlFactory is ERC721Full {

    using SafeMath for uint;

    Cash underlying;
    IaToken aToken;
    IAaveLendingPool aaveLendingPool;
    IAaveLendingPoolCore aaveLendingPoolCore;

    constructor(address _cashAddress, address _aTokenAddress, address _aaveLpAddress, address _aaveLpcoreAddress ) ERC721Full("HodlFactory", "HODL++") public { 
        underlying = Cash(_cashAddress);
        aToken = IaToken(_aTokenAddress); 
        aaveLendingPool = IAaveLendingPool(_aaveLpAddress); 
        aaveLendingPoolCore = IAaveLendingPoolCore(_aaveLpcoreAddress); 

        //create first tier
        tierProperties[0].size = 10;
    }

    uint public hodlCount = 0;
    uint public latestHodlId = 0;
    uint public tierCount = 0;
    uint public averagePurchaseTime = 0;
    uint constant public oneHundredDai = 10**20;
    uint public totalInterestWithdrawn = 0;
    uint public testingVariableA = 69;
    uint public testingVariableB = 0;
    uint public testingVariableC = 0;
    uint public testingVariableD = 0;
    uint public testingVariableE = 0;
    uint public testingVariableF = 0;

    struct hodl {
        uint purchaseTime;
        uint tier;
    }

    struct tier {
        uint size;
        uint hodlsAddedToTier;
        uint hodlsRemovedFromTier;
        uint averagePurchaseTime;
        uint interestAlreadyWithdrawn;
    }

    mapping (uint => hodl) public hodlProperties; 
    mapping (uint => tier) public tierProperties; 
    mapping (address => uint[]) hodlOwnerTracker;

    modifier hodlExists(uint _hodlId) {
        require(ownerOf(_hodlId) != address(0), "Hodl does not exist");
        _;
    }

    function getAdaiBalance() public view returns (uint) {
        return(aToken.balanceOf(address(this)));
    }

    function getHodlsOwned() public view returns(uint[] memory) {
        return(hodlOwnerTracker[msg.sender]);
    }

    function _createNewTier() internal {
        uint _sizeOfBiggestTier = tierProperties[tierCount].size;
        uint _newSize = (_sizeOfBiggestTier.mul(10)).div(9);
        tierCount = tierCount.add(1);
        tierProperties[tierCount].size = _newSize;
    }

    function _addToTier(uint _hodlId) internal {
        //add to existing tier
        uint _hodlsAddedToTier = tierProperties[tierCount].hodlsAddedToTier;
        uint _hodlsRemovedFromTier = tierProperties[tierCount].hodlsRemovedFromTier;
        uint _hodlsInTier = _hodlsAddedToTier.sub(_hodlsRemovedFromTier);
        uint _sizeOfTier = tierProperties[tierCount].size;
        uint _tierAveragePurchaseTime = tierProperties[tierCount].averagePurchaseTime;
        if (_hodlsAddedToTier < _sizeOfTier) {
            tierProperties[tierCount].hodlsAddedToTier = _hodlsAddedToTier.add(1);
            tierProperties[tierCount].averagePurchaseTime = ((_tierAveragePurchaseTime.mul(_hodlsInTier)).add(now)).div(_hodlsInTier.add(1));
        } else {
            _createNewTier();
            _addToTier(_hodlId);
        }
    }

    function getPlayersMyTierOrBelow(uint _hodlId) public view returns (uint) {
        uint _tier = hodlProperties[_hodlId].tier;
        uint _playerCount;
        for (uint i = 0; i <= _tier; i++) {
            _playerCount = _playerCount.add(tierProperties[i].hodlsAddedToTier);
        }
        return _playerCount;
    }

    function createHodl() public {
        // UPDATE VARIABLES
        _addToTier(latestHodlId);
        hodlOwnerTracker[msg.sender].push(latestHodlId);
        hodlProperties[latestHodlId].purchaseTime = now;
        hodlProperties[latestHodlId].tier = tierCount;
        averagePurchaseTime = ((averagePurchaseTime.mul(hodlCount)).add(now)).div(hodlCount.add(1));
        // SWAP DAI FOR aDAI
        underlying.mint(oneHundredDai);
        underlying.approve(address(aaveLendingPoolCore), oneHundredDai);
        aaveLendingPool.deposit(address(underlying), oneHundredDai, 0);
        // // GENERATE NFT
        _mint(msg.sender, latestHodlId);
        hodlCount = hodlCount.add(1);  
        latestHodlId = latestHodlId.add(1); 
    } 

    //change to view
    function getTierInterestAccrued(uint _tierId) public returns (uint) {
        uint _totalAdaiBalance = aToken.balanceOf(address(this)); 
        uint _totalDaiBalance = hodlCount.mul(oneHundredDai);
        uint _totalInterestAvailable = (_totalAdaiBalance.sub(_totalDaiBalance)).add(totalInterestWithdrawn);
        uint _hodlsAddedToTier = tierProperties[_tierId].hodlsAddedToTier;
        uint _interestAlreadyWithdrawn = tierProperties[_tierId].interestAlreadyWithdrawn;
        _totalInterestAvailable = _totalInterestAvailable.sub(_interestAlreadyWithdrawn);
        uint _numerator = now.sub(tierProperties[_tierId].averagePurchaseTime).mul(_hodlsAddedToTier);
        uint _denominator = (now.sub(averagePurchaseTime)).mul(hodlCount);
        testingVariableA = _totalInterestAvailable;
        testingVariableB = _numerator;
        testingVariableC = _denominator;
        testingVariableD = tierProperties[_tierId].averagePurchaseTime;
        testingVariableE = averagePurchaseTime;
        testingVariableF = now;

        return (_totalInterestAvailable.mul(_numerator.div(_denominator)));
    }
    
    // change to view
    function getInterestAvailableToWithdrawView(uint _hodlId) public hodlExists(_hodlId) returns (uint) {
        uint _interestToWithdraw;
        uint _playerCount = getPlayersMyTierOrBelow(_hodlId);
        uint _tier = hodlProperties[_hodlId].tier;
        // tier 0 gets their own interest, any other tier, you do not get your own
        if (_tier != 0) {
            _tier = _tier.add(1);
        }
        for (uint i = _tier; i <= tierCount; i++) {
            uint _tierInterestAccrued = getTierInterestAccrued(i);
            uint _interestToWithdrawFromThisTier = _tierInterestAccrued.div(_playerCount);
            _interestToWithdraw = _interestToWithdraw.add(_interestToWithdrawFromThisTier);
            if (i != 0) {
                // otherwise double counting tier 0 players
                _playerCount = _playerCount.add(tierProperties[i].hodlsAddedToTier);
            }
        }
        return _interestToWithdraw;
    }

    // the same as the above, except that it updates 'interestAlreadyWithdrawn' property of each tier 
    function _getInterestAvailableToWithdraw(uint _hodlId) internal hodlExists(_hodlId) returns (uint) {
        uint _interestToWithdraw;
        uint _playerCount = getPlayersMyTierOrBelow(_hodlId);
        uint _tier = hodlProperties[_hodlId].tier;
        // tier 0 gets their own interest, any other tier, you do not get your own
        if (_tier != 0) {
            _tier = _tier.add(1);
        }
        for (uint i = _tier; i <= tierCount; i++) {
            uint _tierInterestAccrued = getTierInterestAccrued(i);
            uint _interestToWithdrawFromThisTier = _tierInterestAccrued.div(_playerCount);
            testingVariableA = _tierInterestAccrued;
            testingVariableB = _interestToWithdrawFromThisTier;
            testingVariableC = _playerCount;
            _interestToWithdraw = _interestToWithdraw.add(_interestToWithdrawFromThisTier);
            tierProperties[i].interestAlreadyWithdrawn = tierProperties[i].interestAlreadyWithdrawn.add(_interestToWithdrawFromThisTier); // <- only new line from View version
            if (i != 0) {
                // otherwise double counting tier 0 players
                _playerCount = _playerCount.add(tierProperties[i].hodlsAddedToTier);
            }
        }
        return _interestToWithdraw;
    }

    function _withdrawInterest(uint _hodlId) internal {
        uint _interestToWithdraw = _getInterestAvailableToWithdraw(_hodlId);
        totalInterestWithdrawn = totalInterestWithdrawn.add(_interestToWithdraw);
        aToken.redeem(_interestToWithdraw);
        underlying.transfer(ownerOf(_hodlId), _interestToWithdraw);
    } 

    function destroyHodl(uint _hodlId) public {
        require (ownerOf(_hodlId) == msg.sender, "Not owner");
        _withdrawInterest(_hodlId);
        // remove HODL from tier
        uint _tier = hodlProperties[_hodlId].tier;
        uint _hodlsAddedToTier = tierProperties[_tier].hodlsAddedToTier;
        uint _tierAveragePurchaseTime = tierProperties[_tier].averagePurchaseTime;
        if (_hodlsAddedToTier > 1) {
            tierProperties[_tier].averagePurchaseTime = ((_tierAveragePurchaseTime.mul(_hodlsAddedToTier)).sub(hodlProperties[_hodlId].purchaseTime)).div(_hodlsAddedToTier.sub(1));
        } else {
            tierProperties[_tier].averagePurchaseTime = 0;
        }
        tierProperties[_tier].hodlsAddedToTier = tierProperties[_tier].hodlsAddedToTier.sub(1);
        // external calls
        aToken.redeem(oneHundredDai);
        underlying.transfer(ownerOf(_hodlId), oneHundredDai);
        // remove HODL
        hodlCount = hodlCount.sub(1);
        _burn(_hodlId);
    }

}
