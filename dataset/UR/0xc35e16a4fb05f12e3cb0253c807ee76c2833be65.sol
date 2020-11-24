 

pragma solidity 0.4.25;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenSEOS {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

    mapping (address => bool) public blacklist;
    address admin;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    constructor (
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        admin = msg.sender;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!blacklist[msg.sender]);
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function ban(address addr) public {
        require(msg.sender == admin);
        blacklist[addr] = true;
    }

     
    function enable(address addr) public {
        require(msg.sender == admin);
        blacklist[addr] = false;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!blacklist[msg.sender]);
        require(!blacklist[_from]);
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        require(!blacklist[msg.sender]);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
        require(!blacklist[msg.sender]);
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(!blacklist[msg.sender]);
        require(balanceOf[msg.sender] >= _value);    
        require(_value <= totalSupply);
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(!blacklist[msg.sender]);
        require(!blacklist[_from]);
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        require(_value <= totalSupply);
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}