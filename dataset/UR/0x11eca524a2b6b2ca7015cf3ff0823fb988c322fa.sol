 

pragma solidity ^0.5.8;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() internal {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;
   
   
  mapping(address => bool) internal allowedAddresses;
  mapping(address => bool) internal lockedAddresses;
  bool public locked = true;
  
  mapping(address => uint256) internal lockedBalances;
  event LockBalance(address indexed _addr, uint256 _lockAmount);

  function allowAddress(address _addr, bool _allowed) public onlyOwner {
    require(_addr != owner);
    allowedAddresses[_addr] = _allowed;
  }

  function lockAddress(address _addr, bool _locked) public onlyOwner {
    require(_addr != owner);
    lockedAddresses[_addr] = _locked;
  }

  function setLocked(bool _locked) public onlyOwner {
    locked = _locked;
  }

  function canTransfer(address _addr) public view returns (bool) {
    if(locked) {
      if(!allowedAddresses[_addr] && _addr != owner) {
          return false;
      }
    } else if(lockedAddresses[_addr]) {
        return false;
    }

    return true;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(canTransfer(msg.sender));
    require(checkHolderBalance(msg.sender, _value));
    
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  
  function lockBalance(address _addr, uint256 _lockAmount) onlyOwner public {
      require(_addr != address(0));
       
      
      lockedBalances[_addr] = _lockAmount;
      emit LockBalance(_addr, _lockAmount);
  }
  
  function lockedBalanceOf(address _addr) public view returns (uint256) {
      return lockedBalances[_addr];
  }
  
  function checkHolderBalance(address _addr, uint256 _sendAmount) internal view returns (bool) {
      if (balances[_addr] >= lockedBalances[_addr]
        && balances[_addr].sub(lockedBalances[_addr]) >= _sendAmount) {
          return true;
      } else {
          return false;
      }
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(canTransfer(msg.sender));
    require(checkHolderBalance(_from, _value));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

 
contract BurnableToken is StandardToken {
    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
}

contract Token  is BurnableToken {
    string public constant name = "NiX-M";
    string public constant symbol = "NiXM";
    uint256 public constant decimals = 18;
     
    uint256 public constant initialSupply = 10_000_000_000 * (10 ** decimals);

     
    constructor() public {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;  
        allowedAddresses[owner] = true;
    }
}