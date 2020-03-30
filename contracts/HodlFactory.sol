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
    function balanceOf(address _ownesr) external view returns (uint256);
}

contract HodlFactory is ERC721Full {

    using SafeMath for uint256;

    constructor() ERC721Full("HodlFactory", "HODL") public { }

    // Cash public cash; 
    // rinkeby stuff
    ICErc20 cToken = ICErc20(0x6D7F0754FFeb405d23C51CE938289d4835bE3b14); 
    Cash underlying = Cash(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);

    uint256 public classicHodlCount = 0;
    uint256 constant public oneHundredDai = 100000000000000000000;

     struct hodl {
        address owner;
        uint256 purchaseTime;
        uint256 cTokenBalance;
    }

    mapping (uint256 => hodl) public hodlTracker; 

    function getClassicHodlOwner(uint256 _hodlId) external view returns (address) {
        return hodlTracker[_hodlId].owner;
    }

    function getClassicHodlPurchaseTime(uint256 _hodlId) external returns (uint256) {
        return hodlTracker[_hodlId].purchaseTime;
    }

    function getClassicHodlTokenBalance(uint256 _hodlId) external returns (uint256) {
        return hodlTracker[_hodlId].cTokenBalance;
    }

    function buyClassicHodl() external {
        // UPDATE VARIABLES
        hodlTracker[classicHodlCount].owner = msg.sender;
        hodlTracker[classicHodlCount].purchaseTime = now;
         // SWAP DAI FOR cDAI
        underlying.allocateTo(address(this), oneHundredDai); // just send dai to the contract so dont need to worry about approve shit
        underlying.approve(address(cToken), oneHundredDai);
        uint256 _cTokenBalanceBefore = cToken.balanceOf(address(this));
        assert(cToken.mint(oneHundredDai) == 0); 
        uint256 _cTokenBalanceAfter = cToken.balanceOf(address(this));
        hodlTracker[classicHodlCount].cTokenBalance = _cTokenBalanceAfter - _cTokenBalanceBefore;
        // GENERATE NFT
        _mint(msg.sender, classicHodlCount);
        classicHodlCount = classicHodlCount.add(1);
    } 

    // function withdrawInterestfromClassicHodl(uint256 _hodlId) external {
    //     require(msg.sender = ownerOf(_hodlId), "Not owner");
    //     uint256 _daiAvailable = cToken.balanceOfUnderlying(_hodlId)

    // }


  




}
