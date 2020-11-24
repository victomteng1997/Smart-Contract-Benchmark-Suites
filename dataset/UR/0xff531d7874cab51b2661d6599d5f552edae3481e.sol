 

pragma solidity ^0.4.23;

contract CoinCj  
{
     
     
    address public admin_address = 0x587b13913F4c708A4F033318056E4b6BA956A6F5;  
    address public account_address = 0xf988dC2F225C64CcdeA064Dad60DD4A95776f483;  
    
     
    mapping(address => uint256) balances;
    
     
    string public name = "chuangjiu";  
    string public symbol = "CJ";  
    uint8 public decimals = 18;  
    uint256 initSupply = 100000000;  
    uint256 public totalSupply = 0;  

     
    constructor() 
    payable 
    public
    {
        totalSupply = mul(initSupply, 10**uint256(decimals));
        balances[account_address] = totalSupply;

        
    }

    function balanceOf( address _addr ) public view returns ( uint )
    {
        return balances[_addr];
    }

     
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value
    ); 

    function transfer(
        address _to, 
        uint256 _value
    ) 
    public 
    returns (bool) 
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = sub(balances[msg.sender],_value);

            

        balances[_to] = add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    
    mapping (address => mapping (address => uint256)) internal allowed;
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = sub(balances[_from], _value);
        
        
        balances[_to] = add(balances[_to], _value);
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(
        address _spender, 
        uint256 _value
    ) 
    public 
    returns (bool) 
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = add(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } 
        else 
        {
            allowed[msg.sender][_spender] = sub(oldValue, _subtractedValue);
        }
        
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    
     
    bool public direct_drop_switch = true;  
    uint256 public direct_drop_rate = 1000;  
    address public direct_drop_address = 0x587b13913F4c708A4F033318056E4b6BA956A6F5;  
    address public direct_drop_withdraw_address = 0x587b13913F4c708A4F033318056E4b6BA956A6F5;  

    bool public direct_drop_range = false;  
    uint256 public direct_drop_range_start = 1549219320;  
    uint256 public direct_drop_range_end = 1580755320;  

    event TokenPurchase
    (
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

     
    function buyTokens( address _beneficiary ) 
    public 
    payable  
    returns (bool)
    {
        require(direct_drop_switch);
        require(_beneficiary != address(0));

         
        if( direct_drop_range )
        {
             
             
            require(block.timestamp >= direct_drop_range_start && block.timestamp <= direct_drop_range_end);

        }
        
         
         
        
        uint256 tokenAmount = div(mul(msg.value,direct_drop_rate ), 10**18);  
        uint256 decimalsAmount = mul( 10**uint256(decimals), tokenAmount);
        
         
        require
        (
            balances[direct_drop_address] >= decimalsAmount
        );

        assert
        (
            decimalsAmount > 0
        );

        
         
        uint256 all = add(balances[direct_drop_address], balances[_beneficiary]);

        balances[direct_drop_address] = sub(balances[direct_drop_address], decimalsAmount);

            

        balances[_beneficiary] = add(balances[_beneficiary], decimalsAmount);
        
        assert
        (
            all == add(balances[direct_drop_address], balances[_beneficiary])
        );

         
        emit TokenPurchase
        (
            msg.sender,
            _beneficiary,
            msg.value,
            tokenAmount
        );

        return true;

    } 
    

     
     
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public 
    {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal 
    {
        require(_value <= balances[_who]);
        
        balances[_who] = sub(balances[_who], _value);

            

        totalSupply = sub(totalSupply, _value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
    
    
     
    modifier admin_only()
    {
        require(msg.sender==admin_address);
        _;
    }

    function setAdmin( address new_admin_address ) 
    public 
    admin_only 
    returns (bool)
    {
        require(new_admin_address != address(0));
        admin_address = new_admin_address;
        return true;
    }

    
     
    function setDirectDrop( bool status )
    public
    admin_only
    returns (bool)
    {
        direct_drop_switch = status;
        return true;
    }
    
     
    function withDraw()
    public
    {
         
        require(msg.sender == admin_address || msg.sender == direct_drop_withdraw_address);
        require(address(this).balance > 0);
         
        direct_drop_withdraw_address.transfer(address(this).balance);
    }
         
     
    function () external payable
    {
                
                buyTokens(msg.sender);
        
        
           
    }

     
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        if (a == 0) 
        {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        c = a + b;
        assert(c >= a);
        return c;
    }

}