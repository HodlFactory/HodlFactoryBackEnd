pragma solidity >=0.4.21 <0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

interface Cash 
{
    function approve(address _spender, uint _amount) external returns (bool);
    function balanceOf(address _ownesr) external view returns (uint);
    function faucet(uint _amount) external;
    function transfer(address _to, uint _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint _amount) external returns (bool);
    function allocateTo(address recipient, uint value) external;
    function mint(uint256) external;
    function mint2(uint256,address) external;
}
contract rTokenMockup

{

    using SafeMath for uint;

    mapping (address => uint) public daiBalances;
    mapping (address => uint) public rTokenBalances;
    uint constant public oneHundredDai = 10**20;

    Cash underlying;

    constructor(address _cashAddress)  public { 
        underlying = Cash(_cashAddress);
    }

    function balanceOf(address _owner) public view returns (uint)
    {
        return rTokenBalances[_owner];
    }

    function mint(uint mintAmount) public returns (bool)
    {
        underlying.mint2(mintAmount, msg.sender);
        underlying.transferFrom(msg.sender, address(this), mintAmount);
        daiBalances[msg.sender] = daiBalances[msg.sender].add(mintAmount);
        rTokenBalances[msg.sender] = rTokenBalances[msg.sender].add(mintAmount);
        return(true);
    }

    function generate10PercentInterest(address _owner) public {
        uint _10percent = daiBalances[_owner].div(10);
        underlying.allocateTo(address(this), _10percent);
        daiBalances[_owner] = daiBalances[_owner].add(_10percent);
        rTokenBalances[_owner] = rTokenBalances[_owner].add(_10percent);
    }

    function redeem(uint redeemAmount) public returns (bool)
    {
        rTokenBalances[msg.sender] = rTokenBalances[msg.sender].sub(redeemAmount);
        underlying.transfer(msg.sender, redeemAmount);
        return (true);
    }


}