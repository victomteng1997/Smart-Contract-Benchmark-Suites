 

pragma solidity ^0.4.16;

 
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

 
contract BurnableToken is StandardToken {

   
  function burn(uint _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }

  event Burn(address indexed burner, uint indexed value);

}

contract SimpleCoinToken is BurnableToken {
    
  string public constant name = "Bitcoin Bank Token";
   
  string public constant symbol = "MBB";
    
  uint32 public constant decimals = 18;

  uint256 public INITIAL_SUPPLY = 70000000 * 1 ether;
  uint256 public Public_Sale_SUPPLY = 42000000 * 1 ether;
  address for_save=0x51A0aF8dd8cf3EFF0c1422361AcF0c02Cf64c892;
  

  function SimpleCoinToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = Public_Sale_SUPPLY;
    balances[for_save] = INITIAL_SUPPLY-Public_Sale_SUPPLY;
  }
    
}

contract Crowdsale is Ownable {
    
  using SafeMath for uint;
    
  address multisig;

  uint restrictedPercent;

  address restricted;

  SimpleCoinToken public token = new SimpleCoinToken();

  uint start;
    
  uint period;

  uint rate;

  function Crowdsale() {
    multisig = 0x51A0aF8dd8cf3EFF0c1422361AcF0c02Cf64c892;
    restrictedPercent = 40;
    rate = 1000*1 ether;
    start = 1517832000;
    period = 80;
  }

  modifier saleIsOn() {
    require(now > start && now < start + period * 1 days);
    _;
  }

  function createTokens() saleIsOn payable {
    multisig.transfer(msg.value);
    uint tokens = rate.mul(msg.value).div(1 ether);
    uint bonusTokens = 0;
     if(now <= start + 25 days) {
      bonusTokens = tokens.div(5);
    } else if(now > start + 25 days && now < start + 40 days) {
      bonusTokens = tokens.div(10);
    } else if(now >= start + 40 days && now < start + 55 days) {
      bonusTokens = tokens.div(20);
    }
    uint tokensWithBonus = tokens.add(bonusTokens);
    token.transfer(msg.sender, tokensWithBonus);

  }

  function() external payable {
    createTokens();
  }
    
}