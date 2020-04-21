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
    uint public tierCount = 0;
    uint public averagePurchaseTime = 0;
    uint constant public oneHundredDai = 10**20;
    uint public testingVariableA = 69;
    uint public testingVariableB = 0;
    uint public testingVariableC = 0;
    uint public testingVariableD = 0;
    uint public testingVariableE = 0;

    struct hodl {
        uint purchaseTime;
        uint tier;
    }

    struct tier {
        uint size;
        uint hodlsInTier;
        uint averagePurchaseTime;
        uint interestAlreadyWithdrawn;
    }

    mapping (uint => hodl) public hodlProperties; 
    mapping (uint => tier) public tierProperties; 
    mapping (address => uint[]) hodlOwnerTracker;

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

    function addToTier(uint _hodlId) public {
        //add to existing tier
        uint _hodlsInTier = tierProperties[tierCount].hodlsInTier;
        uint _sizeOfTier = tierProperties[tierCount].size;
        uint _tierAveragePurchaseTime = tierProperties[tierCount].averagePurchaseTime;
        if (_hodlsInTier < _sizeOfTier) {
            tierProperties[tierCount].hodlsInTier = _hodlsInTier.add(1);
            tierProperties[tierCount].averagePurchaseTime = ((_tierAveragePurchaseTime.mul(_hodlsInTier)).add(now)).div(_hodlsInTier.add(1));
        } else {
            _createNewTier();
            addToTier(_hodlId);
        }
    }

    function getPlayersMyTierOrBelow(uint _hodlId) public view returns (uint) {
        uint _tier = hodlProperties[_hodlId].tier;
        uint _playerCount;
        for (uint i = 0; i <= _tier; i++) {
            _playerCount = _playerCount.add(tierProperties[tierCount].hodlsInTier);
        }
    }

    function createHodl() public {
        // UPDATE VARIABLES
        hodlOwnerTracker[msg.sender].push(hodlCount);
        hodlProperties[hodlCount].purchaseTime = now;
        hodlProperties[hodlCount].tier = tierCount;
        averagePurchaseTime = ((averagePurchaseTime.mul(hodlCount)).add(now)).div(hodlCount.add(1));
        addToTier(hodlCount);
        // SWAP DAI FOR aDAI
        underlying.mint(oneHundredDai);
        underlying.approve(address(aaveLendingPoolCore), oneHundredDai);
        aaveLendingPool.deposit(address(underlying), oneHundredDai, 0);
        // // GENERATE NFT
        _mint(msg.sender, hodlCount);
        hodlCount = hodlCount.add(1);  
    } 

    function getTierInterestAccrued(uint _tierId) public view returns (uint) {
        uint _totalAdaiBalance = aToken.balanceOf(address(this)); 
        uint _totalDaiBalance = hodlCount.mul(oneHundredDai);
        uint _totalInterestAvailable = _totalAdaiBalance.sub(_totalDaiBalance);
        uint _hodlsInTier = tierProperties[_tierId].hodlsInTier;
        uint _interestAlreadyWithdrawn = tierProperties[_tierId].interestAlreadyWithdrawn;
        uint _numerator = _totalInterestAvailable.mul(now.sub(tierProperties[_tierId].averagePurchaseTime)).mul(_hodlsInTier);
        uint _denominator = (now.sub(averagePurchaseTime)).mul(hodlCount);
        return ((_numerator.div(_denominator)).sub(_interestAlreadyWithdrawn));
    }

    function getInterestAvailableToWithdrawView(uint _hodlId) public view returns (uint) {
        uint _interestToWithdraw;
        uint _playerCount = getPlayersMyTierOrBelow(_hodlId);
        uint _tier = hodlProperties[_hodlId].tier;
        for (uint i = _tier.add(1); i <= tierCount; i++) {
            uint _tierInterestAccrued = getTierInterestAccrued(i);
            uint _interestToWithdrawFromThisTier = _tierInterestAccrued.div(_playerCount);
            _interestToWithdraw = _interestToWithdraw.add(_interestToWithdrawFromThisTier);
            _playerCount = _playerCount.add(tierProperties[i].hodlsInTier);
        }
        return _interestToWithdraw;
    }

    function getInterestAvailableToWithdraw(uint _hodlId) public returns (uint) {
        uint _interestToWithdraw;
        uint _playerCount = getPlayersMyTierOrBelow(_hodlId);
        uint _tier = hodlProperties[_hodlId].tier;
        for (uint i = _tier.add(1); i <= tierCount; i++) {
            uint _tierInterestAccrued = getTierInterestAccrued(i);
            uint _interestToWithdrawFromThisTier = _tierInterestAccrued.div(_playerCount);
            _interestToWithdraw = _interestToWithdraw.add(_interestToWithdrawFromThisTier);
            _playerCount = _playerCount.add(tierProperties[i].hodlsInTier);
            tierProperties[i].interestAlreadyWithdrawn = tierProperties[i].interestAlreadyWithdrawn.add(_interestToWithdrawFromThisTier);
        }
        return _interestToWithdraw;
    }

    function _withdrawInterest(uint _hodlId) internal {
        uint _interestToWithdraw = getInterestAvailableToWithdraw(_hodlId);
        aToken.redeem(_interestToWithdraw);
        underlying.transfer(ownerOf(_hodlId), _interestToWithdraw);
    } 

    function destroyHodl(uint _hodlId) public {
        require (ownerOf(_hodlId) == msg.sender, "Not owner");
        _withdrawInterest(_hodlId);
        // remove HODL from tier
        uint _tier = hodlProperties[_hodlId].tier;
        uint _hodlsInTier = tierProperties[_tier].hodlsInTier;
        uint _tierAveragePurchaseTime = tierProperties[_tier].averagePurchaseTime;
        if (_hodlsInTier > 1) {
            tierProperties[_tier].averagePurchaseTime = ((_tierAveragePurchaseTime.mul(_hodlsInTier)).sub(hodlProperties[_hodlId].purchaseTime)).div(_hodlsInTier.sub(1));
        } else {
            tierProperties[_tier].averagePurchaseTime = 0;
        }
        tierProperties[_tier].hodlsInTier = tierProperties[_tier].hodlsInTier.sub(1);
        // external calls
        aToken.redeem(oneHundredDai);
        underlying.transfer(ownerOf(_hodlId), oneHundredDai);
        // remove HODL
        hodlCount = hodlCount.sub(1);
        _burn(_hodlId);
    }

}
