pragma solidity >=0.4.21 <0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title Dai contract interface
/// @notice Various cash functions
interface Cash 
{
    function approve(address _spender, uint256 _amount) external returns (bool);
    function balanceOf(address _ownesr) external view returns (uint256);
    function faucet(uint256 _amount) external;
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function allocateTo(address recipient, uint256 value) external;
}

interface ICErc20 {
    function mint(uint256 mintAmount) external returns (uint);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getCash() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
}

contract HodlFactory is ERC721Full {

    using SafeMath for uint256;

    constructor() ERC721Full("HodlFactory", "HODL") public { }

    // Cash public cash; 
    // rinkeby stuff
    ICErc20 cToken = ICErc20(0x6D7F0754FFeb405d23C51CE938289d4835bE3b14); 
    Cash underlying = Cash(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);

    uint256 public hodlCount = 0;
    uint256 public numberOfActiveHodls = 0;
    uint256 public sumOfPurchaseTimes = 0;
    uint256 public testVariableA;
    uint256 public testVariableB;
    uint256 public testVariableC;
    uint256 public testVariableD;
    uint256 constant public oneHundredDai = 100000000000000000000;

     struct hodl {
        address owner;
        uint256 purchaseTime;
    }

    mapping (uint256 => hodl) public hodlTracker; 
   
    // constructor(address _addressOfCashContract) public {
    //     cash = Cash(_addressOfCashContract);
    // }

    function buyHodl() external {
        // SEND 100 DAI TO COMPOUND
        underlying.allocateTo(address(this), oneHundredDai); // just send dai to the contract so dont need to worry about approve shit
        underlying.approve(address(cToken), oneHundredDai);
        assert(cToken.mint(oneHundredDai) == 0); 
        // GENERATE NFT
        _mint(msg.sender, hodlCount);
        hodlTracker[hodlCount].owner = msg.sender;
        hodlTracker[hodlCount].purchaseTime = now;
        sumOfPurchaseTimes = sumOfPurchaseTimes.add(now);
        hodlCount = hodlCount.add(1);
        numberOfActiveHodls = numberOfActiveHodls.add(1);
    } 

    // assumes that tokenID = its position, i.e. does not consider possibility of people burning NFTs
    function getPonziWeighting(uint _hodlId, uint _numberOfActiveHodls) public returns (uint256) {
        uint256 _hodlIdBig = _hodlId.mul(100);
        uint256 _numberOfActiveHodlsBig = _numberOfActiveHodls.mul(100);
        testVariableA = _hodlIdBig;
        testVariableB = _numberOfActiveHodlsBig;
        uint256 _numerator = _numberOfActiveHodlsBig.add((_numberOfActiveHodlsBig.sub(100)).div(2)).sub(_hodlIdBig.sub(100));
        testVariableC = _numerator;
        uint256 _denominator = _numberOfActiveHodlsBig.mul(_numberOfActiveHodlsBig);
        testVariableD = _denominator;
        return _numerator.div(_denominator);
    }

    // function interestOwed(uint256 _hodlId) public view {
    //     uint256 _totalDaiPaid = oneHundredDai.mul(numberOfActiveHodls);
    //     uint256 _totalDaiNow = cToken.balanceOfUnderlying(address(this));
    //     uint256 _totalInterest = _totalDaiNow.sub(_totalDaiPaid);
    //     // uint exchangeRateMantissa = cToken.exchangeRateCurrent();
    //     uint256 cDaiToDaiRate =  1;
    //     uint256 _myTimeHeld = now.sub(hodlTracker[_hodlId].purchaseTime);
    //     uint256 _totalTimeHeld = (now.sub(sumOfPurchaseTimes)).mul(numberOfActiveHodls);
    //     uint256 _myInterestShareBeforePonzid = (_totalInterest.mul(_myTimeHeld)).div(_totalTimeHeld);


    // }




}
