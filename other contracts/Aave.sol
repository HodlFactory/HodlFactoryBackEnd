pragma solidity >=0.4.21 <0.7.0;

interface IaToken 
{
    function balanceOf(address _user) external view returns(uint);
    function redeem(uint256 _amount) external;
}

interface IAaveLendingPool 
{
    function deposit( address _reserve, uint256 _amount, uint16 _referralCode) external;
}

interface IAaveLendingPoolCore
{
    function deposit( address _reserve, uint256 _amount, uint16 _referralCode) external;
}

interface Cash 
{
    function approve(address _spender, uint256 _amount) external returns (bool);
    function balanceOf(address _ownesr) external view returns (uint256);
    function faucet(uint256 _amount) external;
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function allocateTo(address recipient, uint256 value) external;
    function mint(uint256) external;
}

contract AaveHodlFactory {
      Cash underlying = Cash(0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD); //Aave Kovan Dai
      IaToken aToken = IaToken(0x58AD4cB396411B691A9AAb6F74545b2C5217FE6a); //Aave kovan aDai
      IAaveLendingPool aaveLendingPool = IAaveLendingPool(0x580D4Fdc4BF8f9b5ae2fb9225D584fED4AD5375c); //Aave kovan Lending Pool
      IAaveLendingPoolCore aaveLendingPoolCore = IAaveLendingPoolCore(0x95D1189Ed88B380E319dF73fF00E479fcc4CFa45); //Aave kovan Lending Pool Core
      
      uint256 constant public oneHundredDai = 100000000000000000000;
      
      function getAtokens() public {
        underlying.mint(oneHundredDai); 
        underlying.approve(address(aaveLendingPoolCore), oneHundredDai);
        aaveLendingPool.deposit(address(underlying), oneHundredDai, 0); 
      }
      
      function redeem() public {
          aToken.redeem(oneHundredDai);
      }
}