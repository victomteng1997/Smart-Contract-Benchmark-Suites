 

pragma solidity 0.4.15;

 
 
contract MultiSigWallet {

   
  uint constant public MAX_OWNER_COUNT = 50;

   
  mapping (uint => Transaction) public transactions;
  mapping (uint => mapping (address => bool)) public confirmations;
  mapping (address => bool) public isOwner;
  address[] public owners;
  uint public required;
  uint public transactionCount;

  struct Transaction {
    address destination;
    uint value;
    bytes data;
    bool executed;
  }

   
  event Confirmation(address indexed sender, uint indexed transactionId);
  event Revocation(address indexed sender, uint indexed transactionId);
  event Submission(uint indexed transactionId);
  event Execution(uint indexed transactionId);
  event ExecutionFailure(uint indexed transactionId);
  event Deposit(address indexed sender, uint value);
  event OwnerAddition(address indexed owner);
  event OwnerRemoval(address indexed owner);
  event RequirementChange(uint required);

   
  modifier onlyWallet() {
    require(msg.sender == address(this));
    _;
  }

  modifier ownerDoesNotExist(address owner) {
    require(!isOwner[owner]);
    _;
  }

  modifier ownerExists(address owner) {
    require(isOwner[owner]);
    _;
  }

  modifier transactionExists(uint transactionId) {
    require(transactions[transactionId].destination != 0);
    _;
  }

  modifier confirmed(uint transactionId, address owner) {
    require(confirmations[transactionId][owner]);
    _;
  }

  modifier notConfirmed(uint transactionId, address owner) {
    require(!confirmations[transactionId][owner]);
    _;
  }

  modifier notExecuted(uint transactionId) {
    require(!transactions[transactionId].executed);
    _;
  }

  modifier notNull(address _address) {
    require(_address != 0);
    _;
  }

  modifier validRequirement(uint ownerCount, uint _required) {
    require(ownerCount <= MAX_OWNER_COUNT && _required <= ownerCount && _required != 0 && ownerCount != 0);
    _;
  }

   
   
   
   
  function MultiSigWallet(address[] _owners, uint _required)
    validRequirement(_owners.length, _required)
  public {
    for (uint i = 0; i < _owners.length; i++) {
      require(!isOwner[_owners[i]] && _owners[i] != 0);
      isOwner[_owners[i]] = true;
    }
    owners = _owners;
    required = _required;
  }

   
   
  function addOwner(address owner)
    onlyWallet
    ownerDoesNotExist(owner)
    notNull(owner)
    validRequirement(owners.length + 1, required)
  public {
    isOwner[owner] = true;
    owners.push(owner);
    OwnerAddition(owner);
  }

   
   
  function removeOwner(address owner)
    onlyWallet
    ownerExists(owner)
  public {
    isOwner[owner] = false;
    for (uint i = 0; i < owners.length - 1; i++) {
      if (owners[i] == owner) {
        owners[i] = owners[owners.length - 1];
        break;
      }
    }
    owners.length -= 1;
    if (required > owners.length) {
      changeRequirement(owners.length);
    }
    OwnerRemoval(owner);
  }

   
   
   
  function replaceOwner(address owner, address newOwner)
    onlyWallet
    ownerExists(owner)
    ownerDoesNotExist(newOwner)
  public {
    for (uint i=0; i<owners.length; i++) {
      if (owners[i] == owner) {
        owners[i] = newOwner;
        break;
      }
    }
    isOwner[owner] = false;
    isOwner[newOwner] = true;
    OwnerRemoval(owner);
    OwnerAddition(newOwner);
  }

   
   
  function changeRequirement(uint _required)
    onlyWallet
    validRequirement(owners.length, _required)
  public {
    required = _required;
    RequirementChange(_required);
  }

   
   
   
   
   
  function submitTransaction(address destination, uint value, bytes data)
    public
    returns (uint transactionId)
  {
    transactionId = addTransaction(destination, value, data);
    confirmTransaction(transactionId);
  }

   
   
  function confirmTransaction(uint transactionId)
    ownerExists(msg.sender)
    transactionExists(transactionId)
    notConfirmed(transactionId, msg.sender)
  public {
    confirmations[transactionId][msg.sender] = true;
    Confirmation(msg.sender, transactionId);
    executeTransaction(transactionId);
  }

   
   
  function revokeConfirmation(uint transactionId)
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
  public {
    confirmations[transactionId][msg.sender] = false;
    Revocation(msg.sender, transactionId);
  }

   
   
  function executeTransaction(uint transactionId)
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
  public {
    if (isConfirmed(transactionId)) {
      Transaction storage txn = transactions[transactionId];
      txn.executed = true;
      if (txn.destination.call.value(txn.value)(txn.data)) {
        Execution(transactionId);
      } else {
        ExecutionFailure(transactionId);
        txn.executed = false;
      }
    }
  }

   
   
   
  function isConfirmed(uint transactionId)
    constant
    public
    returns (bool)
  {
    uint count = 0;
    for (uint i = 0; i < owners.length; i++) {
      if (confirmations[transactionId][owners[i]]) {
        count += 1;
      }
      if (count == required) {
        return true;
      }
    }
  }

   
   
   
   
   
   
  function addTransaction(address destination, uint value, bytes data)
    notNull(destination)
    internal
    returns (uint transactionId)
  {
    transactionId = transactionCount;
    transactions[transactionId] = Transaction({
      destination: destination,
      value: value,
      data: data,
      executed: false
    });
    transactionCount += 1;
    Submission(transactionId);
  }

   
   
   
   
  function getConfirmationCount(uint transactionId)
    constant
    public
    returns (uint count)
  {
    for (uint i=0; i<owners.length; i++) {
      if (confirmations[transactionId][owners[i]]) {
        count += 1;
      }
    }
  }

   
   
   
   
  function getTransactionCount(bool pending, bool executed)
    constant
    public
    returns (uint count)
  {
    for (uint i = 0; i < transactionCount; i++) {
      if ((pending && !transactions[i].executed) || (executed && transactions[i].executed)) {
        count += 1;
      }
    }
  }

   
   
  function getOwners()
    constant
    public
    returns (address[])
  {
    return owners;
  }

   
   
   
  function getConfirmations(uint transactionId)
    constant
    public
    returns (address[] _confirmations)
  {
    address[] memory confirmationsTemp = new address[](owners.length);
    uint count = 0;
    uint i;
    for (i=0; i<owners.length; i++) {
      if (confirmations[transactionId][owners[i]]) {
        confirmationsTemp[count] = owners[i];
        count += 1;
      }
    }
    _confirmations = new address[](count);
    for (i=0; i<count; i++) {
      _confirmations[i] = confirmationsTemp[i];
    }
  }

   
   
   
   
   
   
   
  function getTransactionIds(uint from, uint to, bool pending, bool executed)
    constant
    public
    returns (uint[] _transactionIds)
  {
    require(from <= to || to < transactionCount);
    uint[] memory transactionIdsTemp = new uint[](to - from + 1);
    uint count = 0;
    uint i;
    for (i = from; i <= to; i++) {
      if ((pending && !transactions[i].executed) || (executed && transactions[i].executed)) {
        transactionIdsTemp[count] = i;
        count += 1;
      }
    }
    _transactionIds = new uint[](count);
    for (i=0; i<count; i++) {
      _transactionIds[i] = transactionIdsTemp[i];
    }
  }

   
  function() public payable {
    if (msg.value > 0) {
      Deposit(msg.sender, msg.value);
    }
  }
}