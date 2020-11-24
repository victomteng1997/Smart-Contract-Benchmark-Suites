 

pragma solidity ^0.4.13;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}

 
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
  
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {
    
  address public owner;

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

 

contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}

contract SamsungToken is MintableToken {
    
    string public constant name = "SamsungToken";
    
    string public constant symbol = "SamsungToken";
    
    uint32 public constant decimals = 1;
    
    function SamsungToken (){
        totalSupply = 888888888888888;
    }
    
}


contract SamsungSale is Ownable {
    
    using SafeMath for uint;
    
    address multisig;

    uint restrictedPercent;

    address restricted;

    SamsungToken public token = new SamsungToken();

    uint start;
    
    uint period;

    uint hardcap;

    uint public rate;
    

    function SamsungSale() {
         
    	multisig = 0x1916615552a7AF269E7e78CBA94244BfEfA199c8;
    	
    	 
    	restricted = 0x1916615552a7AF269E7e78CBA94244BfEfA199c8;
    	
    	 
    	restrictedPercent = 0;
    	
    	 
    	rate = 100000000*(1000000000000000000);
    	
    	 
    	start = 1506399914;  
    	period = 64;
    	
    	 
        hardcap = 9500000*(1000000000000000000);
    }
    
     
    modifier saleIsOn() {
    	require(now > start && now < start + period * 1 days);
    	_;
    }
	
	 
    modifier isUnderHardCap() {
        require(token.totalSupply() <= hardcap);
        _;
    }
    
     
    function setRate(uint _rate) onlyOwner {
        rate = _rate;
    }
    
     
    function finishMinting() onlyOwner {
	uint issuedTokenSupply = token.totalSupply();
	uint restrictedTokens = issuedTokenSupply.mul(restrictedPercent).div(100 - restrictedPercent);
	token.mint(restricted, restrictedTokens);
        token.finishMinting();
    }

     
    function createTokens() isUnderHardCap saleIsOn payable {
        
        multisig.transfer(msg.value);
        uint tokens = rate.mul(msg.value).div(1 ether);
        
        token.mint(msg.sender, tokens);
    }

    function() external payable {
        createTokens();
    }
    
}