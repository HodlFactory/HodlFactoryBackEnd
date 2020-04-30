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

    struct hodl {
        uint purchaseTime;
        uint tier;
        string name;
        uint interestAlreadyWithdrawn;
    }

    struct tier {
        uint size;
        uint hodlsInTier;
        uint averagePurchaseTime;
    }

    mapping (uint => hodl) public hodlProperties; 
    mapping (uint => tier) public tierProperties; 
    mapping (address => uint[]) hodlOwnerTracker;
    mapping (address => uint[]) hodlsDeletedTracker;

    modifier hodlExists(uint _hodlId) {
        require(ownerOf(_hodlId) != address(0), "Hodl does not exist");
        _;
    }

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

    function getHodlTier(uint _hodlId) public view returns(uint) {
        return hodlProperties[_hodlId].tier;
    }

    function _createNewTier() internal {
        uint _sizeOfBiggestTier = tierProperties[tierCount].size;
        uint _newSize = (_sizeOfBiggestTier.mul(10)).div(9);
        tierCount = tierCount.add(1);
        tierProperties[tierCount].size = _newSize;
    }

    function _addToTier(uint _hodlId) internal {
        //add to existing tier
        uint _hodlsInTier = tierProperties[tierCount].hodlsInTier;
        uint _sizeOfTier = tierProperties[tierCount].size;
        uint _tierAveragePurchaseTime = tierProperties[tierCount].averagePurchaseTime;
        if (_hodlsInTier < _sizeOfTier) {
            tierProperties[tierCount].hodlsInTier = _hodlsInTier.add(1);
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
            _playerCount = _playerCount.add(tierProperties[i].hodlsInTier);
        }
        return _playerCount;
    }

    function createHodl(string memory _name) public {
        // UPDATE VARIABLES
        _addToTier(latestHodlId);
        hodlOwnerTracker[msg.sender].push(latestHodlId);
        hodlProperties[latestHodlId].purchaseTime = now;
        hodlProperties[latestHodlId].tier = tierCount;
        hodlProperties[latestHodlId].name = _name;
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

    function getTierInterestAccrued(uint _tierId) public view returns (uint) {
        uint _totalAdaiBalance = aToken.balanceOf(address(this)); 
        uint _totalDaiBalance = hodlCount.mul(oneHundredDai);
        uint _totalInterestAvailable = _totalAdaiBalance.sub(_totalDaiBalance);
        uint _hodlsInTier = tierProperties[_tierId].hodlsInTier;
        uint _numerator = (now.sub(tierProperties[_tierId].averagePurchaseTime)).mul(_hodlsInTier);
        uint _denominator = (now.sub(averagePurchaseTime)).mul(hodlCount);
        uint _tierInterest = (_totalInterestAvailable.mul(_numerator)).div(_denominator);
        return _tierInterest;
    }

    function getInterestAvailableToWithdrawView(uint _hodlId) public view hodlExists(_hodlId) returns (uint) {
        uint _interestToWithdraw;
        uint _playerCount = getPlayersMyTierOrBelow(_hodlId);
        uint _tier = hodlProperties[_hodlId].tier;
        for (uint i = _tier.add(1); i <= tierCount; i++) {
            uint _tierInterestAccrued = getTierInterestAccrued(i);
            uint _interestToWithdrawFromThisTier = _tierInterestAccrued.div(_playerCount);
            _interestToWithdraw = _interestToWithdraw.add(_interestToWithdrawFromThisTier);
            _playerCount = _playerCount.add(tierProperties[i].hodlsInTier);
        }
        uint _interestAlreadyWithdrawn = hodlProperties[_hodlId].interestAlreadyWithdrawn;
        if (_interestAlreadyWithdrawn >= _interestToWithdraw) {
            _interestToWithdraw = 0;
        } else {
            _interestToWithdraw = _interestToWithdraw.sub(hodlProperties[_hodlId].interestAlreadyWithdrawn);
        }
        return _interestToWithdraw;
    }

    // the same as the above, except that it updates 'interestAlreadyWithdrawn' property of each hodl 
    function _getInterestAvailableToWithdraw(uint _hodlId) internal hodlExists(_hodlId) returns (uint) {
        uint _interestToWithdraw;
        uint _playerCount = getPlayersMyTierOrBelow(_hodlId);
        uint _tier = hodlProperties[_hodlId].tier;
        for (uint i = _tier.add(1); i <= tierCount; i++) {
            uint _tierInterestAccrued = getTierInterestAccrued(i);
            uint _interestToWithdrawFromThisTier = _tierInterestAccrued.div(_playerCount);
            _interestToWithdraw = _interestToWithdraw.add(_interestToWithdrawFromThisTier);
            _playerCount = _playerCount.add(tierProperties[i].hodlsInTier);
        }
        uint _interestAlreadyWithdrawn = hodlProperties[_hodlId].interestAlreadyWithdrawn;
        if (_interestAlreadyWithdrawn >= _interestToWithdraw) {
            _interestToWithdraw = 0;
        } else {
            _interestToWithdraw = _interestToWithdraw.sub(hodlProperties[_hodlId].interestAlreadyWithdrawn);
        }
        hodlProperties[_hodlId].interestAlreadyWithdrawn = hodlProperties[_hodlId].interestAlreadyWithdrawn.add(_interestToWithdraw); // <- new line
        return _interestToWithdraw;
    }

    function withdrawInterest(uint _hodlId) public {
        uint _interestToWithdraw = _getInterestAvailableToWithdraw(_hodlId);
        if (_interestToWithdraw > 0) {
            aToken.redeem(_interestToWithdraw);
            underlying.transfer(ownerOf(_hodlId), _interestToWithdraw);
        }
    } 

    function destroyHodl(uint _hodlId) public {
        require (ownerOf(_hodlId) == msg.sender, "Not owner");
        withdrawInterest(_hodlId);
        // remove HODL from tier
        uint _tier = hodlProperties[_hodlId].tier;
        uint _hodlsInTier = tierProperties[_tier].hodlsInTier;
        // update tier average purchase time
        uint _tierAveragePurchaseTime = tierProperties[_tier].averagePurchaseTime;
        if (_hodlsInTier > 1) {
            tierProperties[_tier].averagePurchaseTime = ((_tierAveragePurchaseTime.mul(_hodlsInTier)).sub(hodlProperties[_hodlId].purchaseTime)).div(_hodlsInTier.sub(1));
        } else {
            tierProperties[_tier].averagePurchaseTime = 0;
        }
        // update total average purchase time
        if (hodlCount > 1) {
            averagePurchaseTime = ((averagePurchaseTime.mul(hodlCount)).sub(hodlProperties[_hodlId].purchaseTime)).div(hodlCount.sub(1));
        } else {
            averagePurchaseTime = 0;
        }
        tierProperties[_tier].hodlsInTier = tierProperties[_tier].hodlsInTier.sub(1);
        // external calls
        aToken.redeem(oneHundredDai);
        underlying.transfer(ownerOf(_hodlId), oneHundredDai);
        // remove HODL
        hodlCount = hodlCount.sub(1);
        _burn(_hodlId);
        hodlsDeletedTracker[msg.sender].push(_hodlId);
    }

}
