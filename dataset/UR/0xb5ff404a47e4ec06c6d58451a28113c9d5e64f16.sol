 

pragma solidity ^0.4.18;

 
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}
contract TimeChainToken is SafeMath{
    string public name ;
    string public symbol ;
    uint8 public decimals = 8;
    uint256 public totalSupply ;
    address public owner;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    event Freeze(address indexed from, uint256 value);

     
    event Unfreeze(address indexed from, uint256 value);

     
    function TimeChainToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        address holder)  public{
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[holder] = totalSupply;                        
        name = tokenName;                                       
        symbol = tokenSymbol;                                   
        owner = holder;
    }

     
    function transfer(address _to, uint256 _value) public{
        require(_to != 0x0);   
        require(_value > 0); 
        require(balanceOf[msg.sender] >= _value);            
        require(balanceOf[_to] + _value >= balanceOf[_to]);  
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
        Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        require(_value > 0); 
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);                                 
        require(_value > 0); 
        require(balanceOf[_from] >= _value);                  
        require(balanceOf[_to] + _value >= balanceOf[_to]);   
        require(_value <= allowance[_from][msg.sender]);      
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                            
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                              
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }


}