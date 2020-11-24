 

pragma solidity ^0.4.14;
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract OuCoin {
     
    string public standard = 'Token 0.1';
    string public constant name = "OuCoin";
    string public constant symbol = "IOU";
    uint8 public constant decimals = 3;
    uint256 public constant initialSupply = 10000000;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function OuCoin () {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = totalSupply;               
    }

     
    function transfer(address _to, uint256 _value) {
        require (_to != 0x0);                                
        require (balanceOf[msg.sender] >= _value);            
        require (balanceOf[_to] + _value >= balanceOf[_to]);  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require (_to != 0x0);                                 
        require (balanceOf[_from] >= _value);                  
        require (balanceOf[_to] + _value >= balanceOf[_to]);   
        require (_value <= allowance[_from][msg.sender]);      
        balanceOf[_from] -= _value;                            
        balanceOf[_to] += _value;                              
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        require (balanceOf[msg.sender] >= _value);             
        balanceOf[msg.sender] -= _value;                       
        totalSupply -= _value;                                 
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
        require (balanceOf[_from] >= _value);                 
        require (_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                           
        totalSupply -= _value;                                
        Burn(_from, _value);
        return true;
    }
}