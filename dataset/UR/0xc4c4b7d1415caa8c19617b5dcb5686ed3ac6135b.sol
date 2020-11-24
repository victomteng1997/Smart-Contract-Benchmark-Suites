 

pragma solidity ^0.4.11;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract VanityToken is MintableToken, PausableToken {

     
    string public constant symbol = "VIP";
    string public constant name = "VipCoin";
    uint8 public constant decimals = 18;
    string public constant version = "1.0";

}

contract VanityCrowdsale is Ownable {

    using SafeMath for uint256;

     

    uint256 public constant TOKEN_RATE = 1000;  
    uint256 public constant OWNER_TOKENS_PERCENT = 100;  

     

    uint256 public startTime;
    uint256 public endTime;
    address public ownerWallet;
    
    mapping(address => uint) public registeredInDay;
    address[] public participants;
    uint256 public totalUsdAmount;
    uint256 public bonusMultiplier;
    
    VanityToken public token;
    bool public finalized;
    bool public distributed;
    uint256 public distributedCount;
    uint256 public distributedTokens;
    
     

    event Finalized();
    event Distributed();
    
     

    function VanityCrowdsale(uint256 _startTime, uint256 _endTime, address _ownerWallet) public {
        startTime = _startTime;
        endTime = _endTime;
        ownerWallet = _ownerWallet;

        token = new VanityToken();
        token.pause();
    }

    function registered(address wallet) public constant returns(bool) {
        return registeredInDay[wallet] > 0;
    }

    function participantsCount() public constant returns(uint) {
        return participants.length;
    }

    function setOwnerWallet(address _ownerWallet) public onlyOwner {
        require(_ownerWallet != address(0));
        ownerWallet = _ownerWallet;
    }

    function computeTotalEthAmount() public constant returns(uint256) {
        uint256 total = 0;
        for (uint i = 0; i < participants.length; i++) {
            address participant = participants[distributedCount + i];
            total += participant.balance;
        }
        return total;
    }

    function setTotalUsdAmount(uint256 _totalUsdAmount) public onlyOwner {
        totalUsdAmount = _totalUsdAmount;

        if (totalUsdAmount > 10000000) {
            bonusMultiplier = 20;
        } else if (totalUsdAmount > 5000000) {
            bonusMultiplier = 15;
        } else if (totalUsdAmount > 1000000) {
            bonusMultiplier = 10;
        } else if (totalUsdAmount > 100000) {
            bonusMultiplier = 5;
        } else if (totalUsdAmount > 10000) {
            bonusMultiplier = 2;
        } else if (totalUsdAmount == 0) {
            bonusMultiplier = 0;  
        }
    }

     

    function () public payable {
        registerParticipant();
    }

    function registerParticipant() public payable {
        require(!finalized);
        require(startTime <= now && now <= endTime);
        require(registeredInDay[msg.sender] == 0);

        registeredInDay[msg.sender] = 1 + now.sub(startTime).div(24*60*60);
        participants.push(msg.sender);
        if (msg.value > 0) {
             
            msg.sender.transfer(msg.value);
        }
    }

     

    function finalize() public onlyOwner {
        require(!finalized);
        require(now > endTime);

        finalized = true;
        Finalized();
    }

    function participantBonus(address participant) public constant returns(uint) {
        uint day = registeredInDay[participant];
        require(day > 0);

        uint bonus = 0;
        if (day <= 1) {
            bonus = 6;
        } else if (day <= 3) {
            bonus = 5;
        } else if (day <= 7) {
            bonus = 4;
        } else if (day <= 10) {
            bonus = 3;
        } else if (day <= 14) {
            bonus = 2;
        } else if (day <= 21) {
            bonus = 1;
        }

        return bonus.mul(bonusMultiplier);
    }

    function distribute(uint count) public onlyOwner {
        require(finalized && !distributed);
        require(count > 0 && distributedCount + count <= participants.length);
        
        for (uint i = 0; i < count; i++) {
            address participant = participants[distributedCount + i];
            uint256 bonus = participantBonus(participant);
            uint256 tokens = participant.balance.mul(TOKEN_RATE).mul(100 + bonus).div(100);
            token.mint(participant, tokens);
            distributedTokens += tokens;
        }
        distributedCount += count;

        if (distributedCount == participants.length) {
            uint256 ownerTokens = distributedTokens.mul(OWNER_TOKENS_PERCENT).div(100);
            token.mint(ownerWallet, ownerTokens);
            token.finishMinting();
            token.unpause();
            distributed = true;
            Distributed();
        }
    }

}