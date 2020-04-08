pragma solidity >=0.4.21 <0.7.0;

interface Cash 
{
    function approve(address _spender, uint _amount) external returns (bool);
    function balanceOf(address _ownesr) external view returns (uint);
    function faucet(uint _amount) external;
    function transfer(address _to, uint _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint _amount) external returns (bool);
    function allocateTo(address recipient, uint value) external;
    function maxSupply() external returns (uint);
}

interface RToken
{
    function accountStats(address account) external view returns (uint256);
    function mint(uint256 mintAmount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function getMaximumHatID() external view returns (uint256 hatID);
    function interestPayableOf(address owner) external view returns (uint256 amount);
    function payInterest(address owner) external returns (bool);
    function receivedSavingsOf(address owner) external view returns (uint256 amount);
    function receivedLoanOf(address owner) external view returns (uint256 amount);
}

contract myContract {
    Cash underlying = Cash(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    RToken rToken = RToken(0x462303f77a3f17Dbd95eb7bab412FE4937F9B9CB);
    uint constant public oneDai = 10**18; //1000000000000000000
    uint256 public constant MAX_UINT256 = uint256(int256(-1));
    uint256 public maxHatId;
    
    function approveDai() public {
        // underlying.allocateTo(address(this), oneHundredDai);
        underlying.approve(address(rToken), oneDai);
    }
    
    function mintRdai() public {
        rToken.mint(oneDai);
    }
    
    // function getmaxHatId() public {
    //     maxHatId = rToken.getMaximumHatID();
    // }
    
}