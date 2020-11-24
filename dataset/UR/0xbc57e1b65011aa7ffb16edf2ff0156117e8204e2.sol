 

pragma solidity ^0.4.21;
contract MyToken {
    
     
    string public name;
    string public symbol;
    uint8 public decimals;
     
    mapping (address => uint256) public balanceOf;
     
    event Transfer(address indexed from, address indexed to, uint256 value);
     
    function MyToken(uint256 _supply, string _name, string _symbol, uint8 _decimals) public{
         
        if (_supply == 0) _supply = 1000000;
         
        balanceOf[msg.sender] = _supply;
        name = _name;
        symbol = _symbol;
         
        decimals = _decimals;
    }
     
    function transfer(address _to, uint256 _value) public{
         
        if (balanceOf[msg.sender] < _value) require(balanceOf[msg.sender] < _value);
        if (balanceOf[_to] + _value < balanceOf[_to]) require(balanceOf[msg.sender] < _value);
         
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
         
        emit Transfer(msg.sender, _to, _value);
    }
}