 

pragma solidity ^0.4.25;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
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

contract Energem is ERC20 {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public Claimed; 

    string public constant name = "Energem";
    string public constant symbol = "NRGM";
    uint public constant decimals = 18;
    uint public deadline = now + 37 * 1 days;
    uint public round2 = now + 32 * 1 days;
    uint public round1 = now + 22 * 1 days;
    
    uint256 public totalSupply = 3000000000e18;
    uint256 public totalDistributed;
    uint256 public constant requestMinimum = 1 ether / 200;  
    uint256 public tokensPerEth = 250000e18;
    
     
    address multisig = 0x9990e0fD09274f1Ff7b43175b0Ee917071Ef5d01
    ;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();

    event TokensPerEthUpdated(uint _tokensPerEth);
    
    event Burn(address indexed burner, uint256 value);
    
    event Add(uint256 value);

    bool public distributionFinished = false;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        uint256 teamFund = 1000000000e18;
        owner = msg.sender;
        distr(owner, teamFund);
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);        
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }
    
    function Distribute(address _participant, uint _amount) onlyOwner internal {

        require( _amount > 0 );      
        require( totalDistributed < totalSupply );
        balances[_participant] = balances[_participant].add(_amount);
        totalDistributed = totalDistributed.add(_amount);

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }

         
        emit Transfer(address(0), _participant, _amount);
    }

    function updateTokensPerEth(uint _tokensPerEth) public onlyOwner {        
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }
           
    function () external payable {
        getTokens();
     }

    function getTokens() payable canDistr  public {
        uint256 tokens = 0;
        uint256 bonus = 0;
        uint256 countbonus = 0;
        uint256 bonusCond1 = 1 ether / 10;
        uint256 bonusCond2 = 1 ether;
        uint256 bonusCond3 = 5 ether;

        tokens = tokensPerEth.mul(msg.value) / 1 ether;        
        address investor = msg.sender;

        if (msg.value >= requestMinimum && now < deadline && now < round1 && now < round2) {
            if(msg.value >= bonusCond1 && msg.value < bonusCond2){
                countbonus = tokens * 10 / 100;
            }else if(msg.value >= bonusCond2 && msg.value < bonusCond3){
                countbonus = tokens * 20 / 100;
            }else if(msg.value >= bonusCond3){
                countbonus = tokens * 35 / 100;
            }
        }else if(msg.value >= requestMinimum && now < deadline && now > round1 && now < round2){
            if(msg.value >= bonusCond2 && msg.value < bonusCond3){
                countbonus = tokens * 20 / 100;
            }else if(msg.value >= bonusCond3){
                countbonus = tokens * 35 / 100;
            }
        }else{
            countbonus = 0;
        }

        bonus = tokens + countbonus;
        
        if(tokens > 0 && msg.value >= requestMinimum){
            if( now >= deadline && now >= round1 && now < round2){
                distr(investor, tokens);
            }else{
                if(msg.value >= bonusCond1){
                    distr(investor, bonus);
                }else{
                    distr(investor, tokens);
                }   
            }
        }else{
            require( msg.value >= requestMinimum );
        }

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
        
         
        multisig.transfer(msg.value);
    }
    
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint){
        ForeignToken t = ForeignToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdrawAll() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }

    function withdraw(uint256 _wdamount) onlyOwner public {
        uint256 wantAmount = _wdamount;
        owner.transfer(wantAmount);
    }

    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }
    
    function add(uint256 _value) onlyOwner public {
        uint256 counter = totalSupply.add(_value);
        totalSupply = counter; 
        emit Add(_value);
    }
    
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
}