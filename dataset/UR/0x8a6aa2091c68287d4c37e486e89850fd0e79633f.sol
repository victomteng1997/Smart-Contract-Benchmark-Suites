 

pragma solidity 0.4.11;

contract WolkToken {
  mapping (address => uint256) balances;
  mapping (address => uint256) allocations;
  mapping (address => mapping (address => uint256)) allowed;
  mapping (address => mapping (address => bool)) authorized;  

  function transfer(address _to, uint256 _value) isTransferable returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] = safeSub(balances[msg.sender], _value);
      balances[_to] = safeAdd(balances[_to], _value);
      Transfer(msg.sender, _to, _value, balances[msg.sender], balances[_to]);
      return true;
    } else {
      return false;
    }
  }
  
  function transferFrom(address _from, address _to, uint256 _value) isTransferable returns (bool success) {
    var _allowance = allowed[_from][msg.sender];
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] = safeAdd(balances[_to], _value);
      balances[_from] = safeSub(balances[_from], _value);
      allowed[_from][msg.sender] = safeSub(_allowance, _value);
      Transfer(_from, _to, _value, balances[_from], balances[_to]);
      return true;
    } else {
      return false;
    }
  }
 
    
  function settleFrom(address _from, address _to, uint256 _value) isTransferable returns (bool success) {
    var _allowance = allowed[_from][msg.sender];
    var isPreauthorized = authorized[_from][msg.sender];
    if (balances[_from] >= _value && ( isPreauthorized || _allowance >= _value ) && _value > 0) {
      balances[_to] = safeAdd(balances[_to], _value);
      balances[_from] = safeSub(balances[_from], _value);
      Transfer(_from, _to, _value, balances[_from], balances[_to]);
      if (isPreauthorized && _allowance < _value){
          allowed[_from][msg.sender] = 0;
      }else{
          allowed[_from][msg.sender] = safeSub(_allowance, _value);
      }
      return true;
    } else {
      return false;
    }
  }


  function totalSupply() external constant returns (uint256) {
        return generalTokens + reservedTokens;
  }
 

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }


  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }


   
   
  function authorize(address _trustee) returns (bool success) {
    authorized[msg.sender][_trustee] = true;
    Authorization(msg.sender, _trustee);
    return true;
  }

   
   
  function deauthorize(address _trustee_to_remove) returns (bool success) {
    authorized[msg.sender][_trustee_to_remove] = false;
    Deauthorization(msg.sender, _trustee_to_remove);
    return true;
  }

   
   
   
  function checkAuthorization(address _owner, address _trustee) constant returns (bool authorization_status) {
    return authorized[_owner][_trustee];
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


   
  event Transfer(address indexed _from, address indexed _to, uint256 _value, uint from_final_tok, uint to_final_tok);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event Authorization(address indexed _owner, address indexed _trustee);
  event Deauthorization(address indexed _owner, address indexed _trustee_to_remove);

  event NewOwner(address _newOwner);
  event MintEvent(uint reward_tok, address recipient);
  event LogRefund(address indexed _to, uint256 _value);
  event WolkCreated(address indexed _to, uint256 _value);
  event Vested(address indexed _to, uint256 _value);

  modifier onlyOwner { assert(msg.sender == owner); _; }
  modifier isOperational { assert(saleCompleted); _; }
  modifier isTransferable { assert(generalTokens > crowdSaleMin); _;}
  modifier is_not_dust { if (msg.value < dust) throw; _; }  
  
   
  string  public constant name = 'Wolk Coin';
  string  public constant symbol = "WOLK";
  string  public constant version = "1.0";
  uint256 public constant decimals = 18;
  uint256 public constant wolkFund  =  10 * 10**1 * 10**decimals;         
  uint256 public constant crowdSaleMin =  10 * 10**3 * 10**decimals;  
  uint256 public constant crowdSaleMax =  10 * 10**5 * 10**decimals;  
  uint256 public constant tokenExchangeRate = 10000;    
  uint256 public constant dust = 1000000 wei;  

  uint256 public generalTokens = wolkFund;      
  uint256 public reservedTokens;               

  address public owner = 0x5fcf700654B8062B709a41527FAfCda367daE7b1;  
  address public multisigWallet = 0x6968a9b90245cB9bD2506B9460e3D13ED4B2FD1e; 

  uint256 public constant start_block = 3843600;    
  uint256 public end_block = 3847200;               
  uint256 public unlockedAt;                        
  uint256 public end_ts;                            
  
  bool public saleCompleted = false;               
  bool public fairsaleProtection = true;         

 

   
   


   
  function Wolk() onlyOwner {

     
    reservedTokens = 25 * 10**decimals;
    allocations[0x564a3f7d98Eb5B1791132F8875fef582d528d5Cf] = 20;  
    allocations[0x7f512CCFEF05F651A70Fa322Ce27F4ad79b74ffe] = 1;   
    allocations[0x9D203A36cd61b21B7C8c7Da1d8eeB13f04bb24D9] = 2;   
    allocations[0x5fcf700654B8062B709a41527FAfCda367daE7b1] = 1;   
    allocations[0xC28dA4d42866758d0Fc49a5A3948A1f43de491e9] = 1;   
    
    balances[owner] = wolkFund;  
    WolkCreated(owner, wolkFund);
  }

   
  function unlock() external {
    if (now < unlockedAt) throw;
    uint256 vested = allocations[msg.sender] * 10**decimals;
    if (vested < 0 ) throw;  
    allocations[msg.sender] = 0;
    reservedTokens = safeSub(reservedTokens, vested);
    balances[msg.sender] = safeAdd(balances[msg.sender], vested); 
    Vested(msg.sender, vested);
  }

   
  function redeemToken() payable is_not_dust external {
    if (saleCompleted) throw;
    if (block.number < start_block) throw;
    if (block.number > end_block) throw;
    if (msg.value <= dust) throw;
    if (tx.gasprice > 0.46 szabo && fairsaleProtection) throw; 
    if (msg.value > 1 ether && fairsaleProtection) throw; 

    uint256 tokens = safeMul(msg.value, tokenExchangeRate);  
    uint256 checkedSupply = safeAdd(generalTokens, tokens);
    if ( checkedSupply > crowdSaleMax) throw;  
      generalTokens = checkedSupply;
      balances[msg.sender] = safeAdd(balances[msg.sender], tokens);    
      WolkCreated(msg.sender, tokens);  
    
  }
  


   
  function fairsaleProtectionOFF() onlyOwner {
    if ( block.number - start_block < 2000) throw;  
    fairsaleProtection = false;
  }


   
  function finalize() onlyOwner {
    if ( saleCompleted ) throw;
    if ( generalTokens < crowdSaleMin ) throw; 
    if ( block.number < end_block ) throw;  
    saleCompleted = true;
    end_ts = now;
    end_block = block.number; 
    unlockedAt = end_ts + 30 minutes;
    if ( ! multisigWallet.send(this.balance) ) throw;
  }

  function withdraw() onlyOwner{ 		
		if ( this.balance == 0) throw;
		if ( generalTokens < crowdSaleMin) throw;	
        if ( ! multisigWallet.send(this.balance) ) throw;
  }


  function refund() {
    if ( saleCompleted ) throw; 
    if ( block.number < end_block ) throw;   
    if ( generalTokens >= crowdSaleMin ) throw;  
    if ( msg.sender == owner ) throw;
    uint256 Val = balances[msg.sender];
    balances[msg.sender] = 0;
    generalTokens = safeSub(generalTokens, Val);
    uint256 ethVal = safeDiv(Val, tokenExchangeRate);
    LogRefund(msg.sender, ethVal);
    if ( ! msg.sender.send(ethVal) ) throw;
  }
    

   
  
  modifier onlyMinter { assert(msg.sender == minter_address); _; }
 
  address public minter_address = owner;

  
   
   
  
  function mintTokens(uint reward_tok, address recipient) external payable onlyMinter isOperational
  {
    balances[recipient] = safeAdd(balances[recipient], reward_tok);
    generalTokens = safeAdd(generalTokens, reward_tok);
    MintEvent(reward_tok, recipient);
  }

  function changeMintingAddress(address newAddress) onlyOwner returns (bool success) { 
    minter_address = newAddress; 
    return true;
  }

  
   
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  
  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
  
  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  
  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}