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
    function balanceOf(address _ownesr) external view returns (uint);
}

contract ClassicHodlFactory is ERC721Full {

    using SafeMath for uint;

    constructor() ERC721Full("HodlFactory", "HODL") public { }

    // Cash public cash; 
    // rinkeby stuff
    ICErc20 cToken = ICErc20(0x6D7F0754FFeb405d23C51CE938289d4835bE3b14); 
    Cash underlying = Cash(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);

    uint public hodlCount = 0;
    uint constant public oneHundredDai = 100000000000000000000;
    uint public testingVariableA = 0;
    uint public testingVariableB = 0;
    uint public testingVariableC = 0;

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

    function getFxRateTimesOneThousand() public returns (uint) {
        uint _totalCDaiBalance = cToken.balanceOf(address(this)).mul(10000000000); // muliplited by more than 1000 cos cDai has fewer decimal points than Dai;
        uint _totalCDaiBalanceTimesOneThousand = _totalCDaiBalance.mul(1000);
        uint _totalDaiBalance = cToken.balanceOfUnderlying(address(this));
        testingVariableC = _totalCDaiBalanceTimesOneThousand.div(_totalDaiBalance);
        // emit stfu(_totalCDaiBalanceTimesOneThousand);
        // emit stfu(_totalDaiBalance);
        emit stfu(testingVariableC);
        return _totalCDaiBalanceTimesOneThousand.div(_totalDaiBalance);
    }

    function interestAvailableToWithdraw(uint _hodlId) public returns (uint) {
        uint _cTokenBalanceTimesOneThousand = hodlTracker[_hodlId].cTokenBalance.mul(1000);
        uint _daiBalanceUnscaled = _cTokenBalanceTimesOneThousand.div(getFxRateTimesOneThousand());
        uint _daiBalanceScaled = _daiBalanceUnscaled.mul(10000000000);
        emit stfu(_daiBalanceScaled);
        return (_daiBalanceScaled);
    }

    function buyHodl() external {
        // UPDATE VARIABLES
        hodlTracker[hodlCount].owner = msg.sender;
        hodlTracker[hodlCount].purchaseTime = now;
         // SWAP DAI FOR cDAI
        underlying.allocateTo(address(this), oneHundredDai); // just send dai to the contract so dont need to worry about approve shit
        underlying.approve(address(cToken), oneHundredDai);
        uint _cTokenBalanceBefore = cToken.balanceOf(address(this));
        assert(cToken.mint(oneHundredDai) == 0); 
        uint _cTokenBalanceAfter = cToken.balanceOf(address(this));
        hodlTracker[hodlCount].cTokenBalance = _cTokenBalanceAfter - _cTokenBalanceBefore;
        // GENERATE NFT
        _mint(msg.sender, hodlCount);
        hodlCount = hodlCount.add(1);
    } 

    // function withdrawInterestfromClassicHodl(uint _hodlId) external {
    //     require(msg.sender = ownerOf(_hodlId), "Not owner");
    //     uint _daiAvailable = cToken.balanceOfUnderlying(_hodlId)

    // }


  




}
