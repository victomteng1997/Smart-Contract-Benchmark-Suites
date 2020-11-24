 

pragma solidity 0.4.23;


 
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

 
contract ERC20Basic {
     
    uint256 public totalSupply;
  
    function balanceOf(address _owner) public view returns (uint256);
  
    function transfer(address _to, uint256 _amount) public returns (bool);
  
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender) public view returns (uint256);
  
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool);
  
    function approve(address _spender, uint256 _amount) public returns (bool);
  
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

   
    mapping(address => uint256) balances;

   
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(_to != address(0));
        require(balances[msg.sender] >= _amount && _amount > 0 && balances[_to].add(_amount) > balances[_to]);

         
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

   
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {
  
  
    mapping (address => mapping (address => uint256)) internal allowed;


   
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
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

   
    function approve(address _spender, uint256 _amount) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

   
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

}
 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }
}

 
contract Ownable {
    address public owner;


   
    constructor()public {
        owner = msg.sender;
    }


   
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


   
    function transferOwnership(address newOwner)public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
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
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

   
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

 
contract VCTToken is BurnableToken,Ownable,MintableToken {
    string public name ;
    string public symbol ;
    uint8 public decimals = 18 ;
     
      
    function ()public payable {
        revert("Sending ether to the contract is not allowed");
    }
     
      
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
        ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        name = tokenName;
        symbol = tokenSymbol;
        balances[msg.sender] = totalSupply;
         
         
        emit Transfer(address(0), msg.sender, totalSupply);
    }
     
      
    function multiSend(address[]dests, uint[]values)public{
        require(dests.length==values.length, "Number of addresses and values should be same");
        uint256 i = 0;
        while (i < dests.length) {
            transfer(dests[i], values[i]);
            i += 1;
        }
    }
     
      
    function getTokenDetail() public view returns (string, string, uint256) {
        return (name, symbol, totalSupply);
    }
}