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

interface IRToken
{
    function mint(uint256 mintAmount) external returns (bool);
    function balanceOf(address) view external;
    function getMaximumHatID() external view returns (uint256 hatID);
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
    uint constant public oneHundredDai = 1000000000000000000; //this is actually 1 Dai for now
    uint public testingVariableA = 0;
    uint public testingVariableB = 0;
    uint public testingVariableC = 0;

     struct hodl {
        address owner;
        uint purchaseTime;
    }

    mapping (uint => hodl) public hodlTracker; 

    event stfu(uint indexed stfu);

    function getHodlOwner(uint _hodlId) external view returns (address) {
        return hodlTracker[_hodlId].owner;
    }

    function getHodlPurchaseTime(uint _hodlId) external view returns (uint) {
        return hodlTracker[_hodlId].purchaseTime;
    }

    function buyHodl() public {
        // UPDATE VARIABLES
        hodlTracker[hodlCount].owner = msg.sender;
        hodlTracker[hodlCount].purchaseTime = now;
         // SWAP DAI FOR rDAI
        underlying.approve(address(rToken), oneHundredDai);
        assert(rToken.mint(oneHundredDai)); 
        // // GENERATE NFT
        _mint(msg.sender, hodlCount);
        hodlCount = hodlCount.add(1);
    } 

}
