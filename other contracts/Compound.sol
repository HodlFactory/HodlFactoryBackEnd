pragma solidity >=0.4.21 <0.7.0;

interface ICErc20 {
    function underlying() external returns (address);
    function mint(uint256 mintAmount) external returns (uint);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getCash() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function balanceOf(address _ownesr) external view returns (uint256);
    function exchangeRateStored() external view returns (uint);
}

interface Cash 
{
    function approve(address _spender, uint256 _amount) external returns (bool);
    function balanceOf(address _ownesr) external view returns (uint256);
    function faucet(uint256 _amount) external;
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function allocateTo(address recipient, uint256 value) external;
}

contract hodlFactory {
     Cash underlying = Cash(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);
      ICErc20 cToken = ICErc20(0x6D7F0754FFeb405d23C51CE938289d4835bE3b14); 
      uint256 constant public oneHundredDai = 100000000000000000000;
      event cTokenBalance(uint indexed balance);
      
      function redeemUnderlying() public {
        underlying.allocateTo(address(this), oneHundredDai); 
        underlying.approve(address(cToken), oneHundredDai);
        assert(cToken.mint(oneHundredDai) == 0); 
        uint _stfu = cToken.balanceOfUnderlying(address(this));
        emit cTokenBalance(_stfu);
      }
}