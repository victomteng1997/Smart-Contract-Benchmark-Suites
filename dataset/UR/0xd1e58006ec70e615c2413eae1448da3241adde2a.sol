 

pragma solidity 0.4.24;


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
contract ERC20Basic {
     
  uint256 public totalSupply;
  
  function balanceOf(address _owner) public view returns (uint256 balance);
  
  function transfer(address _to, uint256 _amount) public returns (bool success);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);
  
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
  
  function approve(address _spender, uint256 _amount) public returns (bool success);
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

 struct TokenVest
    {
        address vestAddress;
        uint vestTokensLimit;
        uint vestTill;
    }
   
  mapping(address => uint256) balances;
  
   
  TokenVest[] listofVest;

   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(isTransferAllowed(msg.sender,_amount));
    require(_to != address(0));
    require(balances[msg.sender] >= _amount && _amount > 0
        && balances[_to].add(_amount) > balances[_to]);

     
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender, _to, _amount);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

    function isTransferAllowed(address trans_from, uint amt) internal returns(bool)
    {
        for(uint i=0;i<listofVest.length;i++)
        {
            if(listofVest[i].vestAddress==trans_from)
            {
                if(now<=listofVest[i].vestTill)
                {
                    if((balanceOf(trans_from).sub(amt)<listofVest[i].vestTokensLimit))
                    {
                        return false;
                    }
                }
            }
        }
        return true;
    }
}

 
contract StandardToken is ERC20, BasicToken {
  
  
  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
    require(isTransferAllowed(_from,_amount));
    require(_to != address(0));
    require(balances[_from] >= _amount);
    require(allowed[_from][msg.sender] >= _amount);
    require(_amount > 0 && balances[_to].add(_amount) > balances[_to]);

    balances[_from] = balances[_from].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    emit Transfer(_from, _to, _amount);
    return true;
  }

   
  function approve(address _spender, uint256 _amount) public returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract BurnableToken is StandardToken, Ownable {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public onlyOwner{
        require(_value <= balances[msg.sender]);
         
         

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }
}
 
 contract EthereumTravelToken is BurnableToken {
     
     
     string public name ;
     string public symbol ;
     uint8 public decimals = 18 ;
     address public AdvisorsAddress;
     address public TeamAddress;
     address public ReserveAddress;
     
     TokenVest vestObject;
     uint public TeamVestTimeLimit;
    
     
      
     function ()public payable {
         revert();
     }
     
      
     function EthereumTravelToken(
            address wallet,
            uint supply,
            string nam, 
            string symb
            ) public {
         owner = wallet;
         totalSupply = supply;
         totalSupply = totalSupply.mul( 10 ** uint256(decimals));  
         name = nam;
         symbol = symb;
         balances[wallet] = totalSupply;
         TeamAddress=0xACE8841DF22F7b5d112db5f5AE913c7adA3457aF;
         AdvisorsAddress=0x49695C3cB19aA4A32F6f465b54CE62e337A07c7b;
         ReserveAddress=0xec599e12B45BB77B65291C30911d9B2c3991aB3D;
         TeamVestTimeLimit = now + 365 days;
          
         emit Transfer(address(0), msg.sender, totalSupply);
         
          
         transfer(TeamAddress, (totalSupply.mul(18)).div(100));
         
          
         transfer(AdvisorsAddress, (totalSupply.mul(1)).div(100));
         
          
         transfer(ReserveAddress, (totalSupply.mul(21)).div(100));
         
          
         vestTokens(TeamAddress,(totalSupply.mul(18)).div(100),TeamVestTimeLimit);
     }
     
      
    function getTokenDetail() public view returns (string, string, uint256) {
      return (name, symbol, totalSupply);
    }
     
     function vestTokens(address ad, uint tkns, uint timelimit) internal {
      vestObject = TokenVest({
          vestAddress:ad,
          vestTokensLimit:tkns,
          vestTill:timelimit
      });
      listofVest.push(vestObject);
    }
 }