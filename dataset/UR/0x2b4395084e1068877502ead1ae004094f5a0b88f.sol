 

pragma solidity ^0.4.24;

 

 

 
  

contract SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}




 
contract Token {
  
  function totalSupply() public view returns (uint256 supply);
  function balanceOf(address _owner)public view returns (uint256 balance);
  function transfer(address _to, uint256 _value)public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value)public returns (bool success);
  function approve(address _spender, uint256 _value)public returns (bool success);
  function allowance(address _owner, address _spender)public view returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



 
contract AbstractToken is Token, SafeMath {
   
 constructor() public{
     
  }
  
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return accounts [_owner];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(_to != address(0));
    if (accounts [msg.sender] < _value) return false;
    if (_value > 0 && msg.sender != _to) {
      accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    emit Transfer (msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public
  returns (bool success) {
    require(_to != address(0));
    if (allowances [_from][msg.sender] < _value) return false;
    if (accounts [_from] < _value) return false; 

    if (_value > 0 && _from != _to) {
	  allowances [_from][msg.sender] = safeSub (allowances [_from][msg.sender], _value);
      accounts [_from] = safeSub (accounts [_from], _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    emit Transfer(_from, _to, _value);
    return true;
  }

   
   function approve (address _spender, uint256 _value) public returns (bool success) {
    allowances [msg.sender][_spender] = _value;
    emit Approval (msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view
  returns (uint256 remaining) {
    return allowances [_owner][_spender];
  }

   
  mapping (address => uint256) accounts;

   
  mapping (address => mapping (address => uint256)) private allowances;
  
}


 
contract P2PToken is AbstractToken {
   
   
   
  uint256 constant MAX_TOKEN_COUNT = 100000000 * (10**18);
   
   
  address private owner;
  
   
  
  mapping (address => bool) private burningAccount;
  
 
   
  uint256 tokenCount = 0;
  
 
   
  constructor() public{
    owner = msg.sender;
  }

   
  function totalSupply() public view returns (uint256 supply) {
    return tokenCount;
  }

  string constant public name = "Peer 2 Peer Global Network";
  string constant public symbol = "P2P";
  uint8 constant public decimals = 18;
  
   
  function transfer(address _to, uint256 _value) public returns (bool success) {
     return AbstractToken.transfer (_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public
    returns (bool success) {
    return AbstractToken.transferFrom (_from, _to, _value);
  }

    
  function approve (address _spender, uint256 _value) public
    returns (bool success) {
	require(allowance (msg.sender, _spender) == 0 || _value == 0);
    return AbstractToken.approve (_spender, _value);
  }

   
  function createTokens(uint256 _value) public
    returns (bool success) {
    require (msg.sender == owner);

    if (_value > 0) {
      if (_value > safeSub (MAX_TOKEN_COUNT, tokenCount)) return false;
	  
      accounts [msg.sender] = safeAdd (accounts [msg.sender], _value);
      tokenCount = safeAdd (tokenCount, _value);
	  
	   
	  emit Transfer(address(0), msg.sender, _value);
	  
	  return true;
    }
	
	  return false;
    
  }
  
   
  function burningCapableAccount(address[] _target) public {
  
      require (msg.sender == owner);
	  
	  for (uint i = 0; i < _target.length; i++) {
			burningAccount[_target[i]] = true;
        }
 }
  
   
  
  function burn(uint256 _value) public returns (bool success) {
  
        require(accounts[msg.sender] >= _value); 
		
		require(burningAccount[msg.sender]);
		
		accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
		
        tokenCount = safeSub (tokenCount, _value);	
		
        emit Burn(msg.sender, _value);
		
        return true;
    }
  

  
  
  
   
  function setOwner(address _newOwner) public{
    require (msg.sender == owner);

    owner = _newOwner;
  }
  
  
   
  
  function refundTokens(address _token, address _refund, uint256 _value) public {
    require (msg.sender == owner);
    require(_token != address(this));
    AbstractToken token = AbstractToken(_token);
    token.transfer(_refund, _value);
    emit RefundTokens(_token, _refund, _value);
  }
  
      
  
  event Burn(address target,uint256 _value);


  
   
  
  event RefundTokens(address _token, address _refund, uint256 _value);
}