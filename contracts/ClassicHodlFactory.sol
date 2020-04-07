pragma solidity >=0.4.21 <0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title Dai contract interface
/// @notice Various cash functions
interface Cash 
{
    function approve(address _spender, uint _amount) external returns (bool);
    function balanceOf(address _ownesr) external view returns (uint);
    function faucet(uint _amount) external;
    function transfer(address _to, uint _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint _amount) external returns (bool);
    function allocateTo(address recipient, uint value) external;
}

interface ICErc20 {
    function mint(uint mintAmount) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getCash() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function balanceOf(address _owners) external view returns (uint);
    function exchangeRateStored() external view returns (uint);
}

contract ClassicHodlFactory is ERC721Full {

    using SafeMath for uint;

    ICErc20 cToken;
    Cash underlying;

    address public cashAddress;

    constructor(address _cashAddress, address _cTokenAddress) ERC721Full("HodlFactory", "HODL") public { 
        cToken = ICErc20(_cTokenAddress); 
        underlying = Cash(_cashAddress);
        cashAddress = _cashAddress;
    }

    uint public hodlCount = 0;
    uint constant public oneHundredDai = 10**20;
    uint public testingVariableA = 0;
    uint public testingVariableB = 0;
    uint public testingVariableC = 0;
    uint public testingVariableD = 0;
    uint public testingVariableE = 0;

     struct hodl {
        address owner;
        uint purchaseTime;
        uint cTokenBalance;
    }

    mapping (uint => hodl) public hodlTracker; 

    event stfu(uint indexed stfu);

    function getHodlOwner(uint _hodlId) external view returns (address) {
        return hodlTracker[_hodlId].owner;
    }

    function getHodlPurchaseTime(uint _hodlId) external view returns (uint) {
        return hodlTracker[_hodlId].purchaseTime;
    }

    function getHodlTokenBalance(uint _hodlId) external view returns (uint) {
        return hodlTracker[_hodlId].cTokenBalance;
    }

    // x 1000 to increase FX rate resolution
    function getFxRateTimesOneThousand() public returns (uint) {
        uint _totalCDaiBalance = cToken.balanceOf(address(this)).mul(10000000000); // scales it up to atto cDai
        uint _totalCDaiBalanceTimesOneThousand = _totalCDaiBalance.mul(1000); 
        uint _totalDaiBalance = cToken.balanceOfUnderlying(address(this));
        return _totalCDaiBalanceTimesOneThousand.div(_totalDaiBalance);
    }

    // function getActuaInterestAvailableToWithdraw(uint _hodlId) public returns (uint) {
    //     uint _cTokenBalanceTimesOneThousand = hodlTracker[_hodlId].cTokenBalance.mul(1000);
    //     uint _daiBalance = _cTokenBalanceTimesOneThousand.div(getFxRateTimesOneThousand());
    //     return (_daiBalance.sub(oneHundredDai);
    // }

    function getEstimatedInterestAvailableToWithdraw(uint _hodlId) public view returns (uint) {
        uint _cTokenBalance = hodlTracker[_hodlId].cTokenBalance;
        uint _daiBalance = (cToken.exchangeRateStored().mul(_cTokenBalance)).div(10**17);
        return (_daiBalance - oneHundredDai);
    }

    function getEstimatedHodlValue(uint _hodlId) public  returns (uint) {
        uint _cTokenBalance = hodlTracker[_hodlId].cTokenBalance;
        testingVariableA = _cTokenBalance;
        testingVariableB = cToken.exchangeRateStored();
        testingVariableC = cToken.exchangeRateStored().mul(_cTokenBalance);
        uint _daiBalance = (cToken.exchangeRateStored().mul(_cTokenBalance)).div(10**28);
        testingVariableD = _daiBalance;
        // testingVariableD = 
        return (_daiBalance);
    }

    function buyHodl() public {
        // UPDATE VARIABLES
        hodlTracker[hodlCount].owner = msg.sender;
        hodlTracker[hodlCount].purchaseTime = now;
         // SWAP DAI FOR cDAI
        underlying.allocateTo(address(this), oneHundredDai); // just send dai to the contract so dont need to worry about approve shit
        underlying.approve(address(cToken), oneHundredDai);
        uint _cTokenBalanceBefore = cToken.balanceOf(address(this)).mul(10000000000); // scales it up to atto cDai
        assert(cToken.mint(oneHundredDai) == 0); 
        uint _cTokenBalanceAfter = cToken.balanceOf(address(this)).mul(10000000000); // scales it up to atto cDai
        hodlTracker[hodlCount].cTokenBalance = _cTokenBalanceAfter - _cTokenBalanceBefore;
        // // GENERATE NFT
        _mint(msg.sender, hodlCount);
        hodlCount = hodlCount.add(1);
    } 

    // function withdrawInterest(uint _hodlId) external {
    //     address _owner = hodlTracker[_hodlId].owner;
    //     uint _actualinterestAvailableToWithdraw = getActuaInterestAvailableToWithdraw(_hodlId);
    //     require(_actualinterestAvailableToWithdraw > 0, "No interest to withdraw");
    //     uint _denominator = (oneHundredDai.add(_actualinterestAvailableToWithdraw)).div(_actualinterestAvailableToWithdraw);
    //     uint _cTokensToWithdraw = hodlTracker[_hodlId].cTokenBalance.div(_denominator);
    //     uint _daiToReturn = cToken.redeemUnderlying(_cTokensToWithdraw.div(10000000000));
    //     underlying.transfer(_owner ,_daiToReturn);
    //     // testingVariableA = _cTokensToWithdraw;
    //     // emit stfu(testingVariableA);
    // }

}
