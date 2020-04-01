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
}
contract cTokenMockup

{

    using SafeMath for uint;

    mapping (address => uint) public daiBalances;
    mapping (address => uint) public cTokenBalances;

    Cash underlying;

    constructor(address _cashAddress)  public { 
        underlying = Cash(_cashAddress);
    }

    function balanceOf(address _owner) public view returns (uint)
    {
        // require(false, "STFU");
        // return cTokenBalances[_owner];
        return 5;
    }

    function balanceOfUnderlying(address _owner) public view returns (uint)
    {
        return daiBalances[_owner];
    }

    function generate10PercentInterest(address _owner) public {
        uint _10percent = daiBalances[_owner].div(10);
        underlying.allocateTo(address(this), _10percent);
        daiBalances[_owner] = daiBalances[_owner].add(_10percent);
    }

    function mint(uint mintAmount) public returns (uint)
    {
        underlying.transferFrom(msg.sender, address(this), mintAmount);
        daiBalances[msg.sender] = mintAmount;
        cTokenBalances[msg.sender] = (mintAmount.mul(50)).div(10000000000);
        return 0;
    }

    function redeemUnderlying(uint redeemAmount) public returns (uint)
    {
        uint _proportion = cTokenBalances[msg.sender].div(redeemAmount);
        underlying.transfer(msg.sender, daiBalances[msg.sender].div(_proportion));
        return 0;
    }


}