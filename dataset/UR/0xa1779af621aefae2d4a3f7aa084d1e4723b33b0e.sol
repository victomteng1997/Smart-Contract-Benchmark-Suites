 

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.4;



 

contract Reputation is Ownable {

    uint8 public decimals = 18;              
     
    event Mint(address indexed _to, uint256 _amount);
     
    event Burn(address indexed _from, uint256 _amount);

       
       
       
    struct Checkpoint {

     
        uint128 fromBlock;

           
        uint128 value;
    }

       
       
       
    mapping (address => Checkpoint[]) balances;

       
    Checkpoint[] totalSupplyHistory;

     
    constructor(
    ) public
    {
    }

     
     
    function totalSupply() public view returns (uint256) {
        return totalSupplyAt(block.number);
    }

   
   
   
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

       
       
       
       
    function balanceOfAt(address _owner, uint256 _blockNumber)
    public view returns (uint256)
    {
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            return 0;
           
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

       
       
       
    function totalSupplyAt(uint256 _blockNumber) public view returns(uint256) {
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            return 0;
           
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

       
       
       
       
    function mint(address _user, uint256 _amount) public onlyOwner returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint256 previousBalanceTo = balanceOf(_user);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_user], previousBalanceTo + _amount);
        emit Mint(_user, _amount);
        return true;
    }

       
       
       
       
    function burn(address _user, uint256 _amount) public onlyOwner returns (bool) {
        uint256 curTotalSupply = totalSupply();
        uint256 amountBurned = _amount;
        uint256 previousBalanceFrom = balanceOf(_user);
        if (previousBalanceFrom < amountBurned) {
            amountBurned = previousBalanceFrom;
        }
        updateValueAtNow(totalSupplyHistory, curTotalSupply - amountBurned);
        updateValueAtNow(balances[_user], previousBalanceFrom - amountBurned);
        emit Burn(_user, amountBurned);
        return true;
    }

   
   
   

       
       
       
       
    function getValueAt(Checkpoint[] storage checkpoints, uint256 _block) internal view returns (uint256) {
        if (checkpoints.length == 0) {
            return 0;
        }

           
        if (_block >= checkpoints[checkpoints.length-1].fromBlock) {
            return checkpoints[checkpoints.length-1].value;
        }
        if (_block < checkpoints[0].fromBlock) {
            return 0;
        }

           
        uint256 min = 0;
        uint256 max = checkpoints.length-1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

       
       
       
       
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint256 _value) internal {
        require(uint128(_value) == _value);  
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
            oldCheckPoint.value = uint128(_value);
        }
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

 

pragma solidity ^0.5.4;





 

contract DAOToken is ERC20, ERC20Burnable, Ownable {

    string public name;
    string public symbol;
     
    uint8 public constant decimals = 18;
    uint256 public cap;

     
    constructor(string memory _name, string memory _symbol, uint256 _cap)
    public {
        name = _name;
        symbol = _symbol;
        cap = _cap;
    }

     
    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        if (cap > 0)
            require(totalSupply().add(_amount) <= cap);
        _mint(_to, _amount);
        return true;
    }
}

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

 
pragma solidity ^0.5.4;



library SafeERC20 {
    using Address for address;

    bytes4 constant private TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 constant private TRANSFERFROM_SELECTOR = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 constant private APPROVE_SELECTOR = bytes4(keccak256(bytes("approve(address,uint256)")));

    function safeTransfer(address _erc20Addr, address _to, uint256 _value) internal {

         
        require(_erc20Addr.isContract());

        (bool success, bytes memory returnValue) =
         
        _erc20Addr.call(abi.encodeWithSelector(TRANSFER_SELECTOR, _to, _value));
         
        require(success);
         
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }

    function safeTransferFrom(address _erc20Addr, address _from, address _to, uint256 _value) internal {

         
        require(_erc20Addr.isContract());

        (bool success, bytes memory returnValue) =
         
        _erc20Addr.call(abi.encodeWithSelector(TRANSFERFROM_SELECTOR, _from, _to, _value));
         
        require(success);
         
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }

    function safeApprove(address _erc20Addr, address _spender, uint256 _value) internal {

         
        require(_erc20Addr.isContract());

         
         
        require((_value == 0) || (IERC20(_erc20Addr).allowance(address(this), _spender) == 0));

        (bool success, bytes memory returnValue) =
         
        _erc20Addr.call(abi.encodeWithSelector(APPROVE_SELECTOR, _spender, _value));
         
        require(success);
         
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }
}

 

pragma solidity ^0.5.4;







 
contract Avatar is Ownable {
    using SafeERC20 for address;

    string public orgName;
    DAOToken public nativeToken;
    Reputation public nativeReputation;

    event GenericCall(address indexed _contract, bytes _data, uint _value, bool _success);
    event SendEther(uint256 _amountInWei, address indexed _to);
    event ExternalTokenTransfer(address indexed _externalToken, address indexed _to, uint256 _value);
    event ExternalTokenTransferFrom(address indexed _externalToken, address _from, address _to, uint256 _value);
    event ExternalTokenApproval(address indexed _externalToken, address _spender, uint256 _value);
    event ReceiveEther(address indexed _sender, uint256 _value);
    event MetaData(string _metaData);

     
    constructor(string memory _orgName, DAOToken _nativeToken, Reputation _nativeReputation) public {
        orgName = _orgName;
        nativeToken = _nativeToken;
        nativeReputation = _nativeReputation;
    }

     
    function() external payable {
        emit ReceiveEther(msg.sender, msg.value);
    }

     
    function genericCall(address _contract, bytes memory _data, uint256 _value)
    public
    onlyOwner
    returns(bool success, bytes memory returnValue) {
       
        (success, returnValue) = _contract.call.value(_value)(_data);
        emit GenericCall(_contract, _data, _value, success);
    }

     
    function sendEther(uint256 _amountInWei, address payable _to) public onlyOwner returns(bool) {
        _to.transfer(_amountInWei);
        emit SendEther(_amountInWei, _to);
        return true;
    }

     
    function externalTokenTransfer(IERC20 _externalToken, address _to, uint256 _value)
    public onlyOwner returns(bool)
    {
        address(_externalToken).safeTransfer(_to, _value);
        emit ExternalTokenTransfer(address(_externalToken), _to, _value);
        return true;
    }

     
    function externalTokenTransferFrom(
        IERC20 _externalToken,
        address _from,
        address _to,
        uint256 _value
    )
    public onlyOwner returns(bool)
    {
        address(_externalToken).safeTransferFrom(_from, _to, _value);
        emit ExternalTokenTransferFrom(address(_externalToken), _from, _to, _value);
        return true;
    }

     
    function externalTokenApproval(IERC20 _externalToken, address _spender, uint256 _value)
    public onlyOwner returns(bool)
    {
        address(_externalToken).safeApprove(_spender, _value);
        emit ExternalTokenApproval(address(_externalToken), _spender, _value);
        return true;
    }

     
    function metaData(string memory _metaData) public onlyOwner returns(bool) {
        emit MetaData(_metaData);
        return true;
    }


}

 

pragma solidity ^0.5.4;


contract GlobalConstraintInterface {

    enum CallPhase { Pre, Post, PreAndPost }

    function pre( address _scheme, bytes32 _params, bytes32 _method ) public returns(bool);
    function post( address _scheme, bytes32 _params, bytes32 _method ) public returns(bool);
     
    function when() public returns(CallPhase);
}

 

pragma solidity ^0.5.4;



 
interface ControllerInterface {

     
    function mintReputation(uint256 _amount, address _to, address _avatar)
    external
    returns(bool);

     
    function burnReputation(uint256 _amount, address _from, address _avatar)
    external
    returns(bool);

     
    function mintTokens(uint256 _amount, address _beneficiary, address _avatar)
    external
    returns(bool);

   
    function registerScheme(address _scheme, bytes32 _paramsHash, bytes4 _permissions, address _avatar)
    external
    returns(bool);

     
    function unregisterScheme(address _scheme, address _avatar)
    external
    returns(bool);

     
    function unregisterSelf(address _avatar) external returns(bool);

     
    function addGlobalConstraint(address _globalConstraint, bytes32 _params, address _avatar)
    external returns(bool);

     
    function removeGlobalConstraint (address _globalConstraint, address _avatar)
    external  returns(bool);

   
    function upgradeController(address _newController, Avatar _avatar)
    external returns(bool);

     
    function genericCall(address _contract, bytes calldata _data, Avatar _avatar, uint256 _value)
    external
    returns(bool, bytes memory);

   
    function sendEther(uint256 _amountInWei, address payable _to, Avatar _avatar)
    external returns(bool);

     
    function externalTokenTransfer(IERC20 _externalToken, address _to, uint256 _value, Avatar _avatar)
    external
    returns(bool);

     
    function externalTokenTransferFrom(
    IERC20 _externalToken,
    address _from,
    address _to,
    uint256 _value,
    Avatar _avatar)
    external
    returns(bool);

     
    function externalTokenApproval(IERC20 _externalToken, address _spender, uint256 _value, Avatar _avatar)
    external
    returns(bool);

     
    function metaData(string calldata _metaData, Avatar _avatar) external returns(bool);

     
    function getNativeReputation(address _avatar)
    external
    view
    returns(address);

    function isSchemeRegistered( address _scheme, address _avatar) external view returns(bool);

    function getSchemeParameters(address _scheme, address _avatar) external view returns(bytes32);

    function getGlobalConstraintParameters(address _globalConstraint, address _avatar) external view returns(bytes32);

    function getSchemePermissions(address _scheme, address _avatar) external view returns(bytes4);

     
    function globalConstraintsCount(address _avatar) external view returns(uint, uint);

    function isGlobalConstraintRegistered(address _globalConstraint, address _avatar) external view returns(bool);
}

 

pragma solidity ^0.5.4;



 

contract Locking4Reputation {
    using SafeMath for uint256;

    event Redeem(address indexed _beneficiary, uint256 _amount);
    event Release(bytes32 indexed _lockingId, address indexed _beneficiary, uint256 _amount);
    event Lock(address indexed _locker, bytes32 indexed _lockingId, uint256 _amount, uint256 _period);

    struct Locker {
        uint256 amount;
        uint256 releaseTime;
    }

    Avatar public avatar;

     
    mapping(address => mapping(bytes32=>Locker)) public lockers;
     
    mapping(address => uint) public scores;

    uint256 public totalLocked;
    uint256 public totalLockedLeft;
    uint256 public totalScore;
    uint256 public lockingsCounter;  
    uint256 public reputationReward;
    uint256 public reputationRewardLeft;
    uint256 public lockingEndTime;
    uint256 public maxLockingPeriod;
    uint256 public lockingStartTime;
    uint256 public redeemEnableTime;

     
    function redeem(address _beneficiary) public returns(uint256 reputation) {
         
        require(block.timestamp > redeemEnableTime, "now > redeemEnableTime");
        require(scores[_beneficiary] > 0, "score should be > 0");
        uint256 score = scores[_beneficiary];
        scores[_beneficiary] = 0;
        uint256 repRelation = score.mul(reputationReward);
        reputation = repRelation.div(totalScore);

         
        reputationRewardLeft = reputationRewardLeft.sub(reputation);
        require(
        ControllerInterface(
        avatar.owner())
        .mintReputation(reputation, _beneficiary, address(avatar)), "mint reputation should succeed");

        emit Redeem(_beneficiary, reputation);
    }

     
    function _release(address _beneficiary, bytes32 _lockingId) internal returns(uint256 amount) {
        Locker storage locker = lockers[_beneficiary][_lockingId];
        require(locker.amount > 0, "amount should be > 0");
        amount = locker.amount;
        locker.amount = 0;
         
        require(block.timestamp > locker.releaseTime, "check the lock period pass");
        totalLockedLeft = totalLockedLeft.sub(amount);

        emit Release(_lockingId, _beneficiary, amount);
    }

     
    function _lock(
        uint256 _amount,
        uint256 _period,
        address _locker,
        uint256 _numerator,
        uint256 _denominator)
        internal
        returns(bytes32 lockingId)
        {
        require(_amount > 0, "locking amount should be > 0");
        require(_period <= maxLockingPeriod, "locking period should be <= maxLockingPeriod");
        require(_period > 0, "locking period should be > 0");
         
        require(now <= lockingEndTime, "lock should be within the allowed locking period");
         
        require(now >= lockingStartTime, "lock should start after lockingStartTime");

        lockingId = keccak256(abi.encodePacked(address(this), lockingsCounter));
        lockingsCounter = lockingsCounter.add(1);

        Locker storage locker = lockers[_locker][lockingId];
        locker.amount = _amount;
         
        locker.releaseTime = now + _period;
        totalLocked = totalLocked.add(_amount);
        totalLockedLeft = totalLockedLeft.add(_amount);
        uint256 score = _period.mul(_amount).mul(_numerator).div(_denominator);
        require(score > 0, "score must me > 0");
        scores[_locker] = scores[_locker].add(score);
         
        require((scores[_locker] * reputationReward)/scores[_locker] == reputationReward,
        "score is too high");
        totalScore = totalScore.add(score);

        emit Lock(_locker, lockingId, _amount, _period);
    }

     
    function _initialize(
        Avatar _avatar,
        uint256 _reputationReward,
        uint256 _lockingStartTime,
        uint256 _lockingEndTime,
        uint256 _redeemEnableTime,
        uint256 _maxLockingPeriod)
    internal
    {
        require(avatar == Avatar(0), "can be called only one time");
        require(_avatar != Avatar(0), "avatar cannot be zero");
        require(_lockingEndTime > _lockingStartTime, "locking end time should be greater than locking start time");
        require(_redeemEnableTime >= _lockingEndTime, "redeemEnableTime >= lockingEndTime");

        reputationReward = _reputationReward;
        reputationRewardLeft = _reputationReward;
        lockingEndTime = _lockingEndTime;
        maxLockingPeriod = _maxLockingPeriod;
        avatar = _avatar;
        lockingStartTime = _lockingStartTime;
        redeemEnableTime = _redeemEnableTime;
    }

}

 

pragma solidity ^0.5.4;


 

contract LockingEth4Reputation is Locking4Reputation {

     
    function initialize(
        Avatar _avatar,
        uint256 _reputationReward,
        uint256 _lockingStartTime,
        uint256 _lockingEndTime,
        uint256 _redeemEnableTime,
        uint256 _maxLockingPeriod)
    external
    {
        super._initialize(
        _avatar,
        _reputationReward,
        _lockingStartTime,
        _lockingEndTime,
        _redeemEnableTime,
        _maxLockingPeriod);
    }

     
    function release(address payable _beneficiary, bytes32 _lockingId) public returns(bool) {
        uint256 amount = super._release(_beneficiary, _lockingId);
        _beneficiary.transfer(amount);

        return true;
    }

     
    function lock(uint256 _period) public payable returns(bytes32 lockingId) {
        return super._lock(msg.value, _period, msg.sender, 1, 1);
    }

}

 

pragma solidity ^0.5.4;


 
contract DxLockEth4Rep is LockingEth4Reputation {
    constructor() public {}
}

 

pragma solidity ^0.5.4;


 

contract ExternalLocking4Reputation is Locking4Reputation {

    event Register(address indexed _beneficiary);

    address public externalLockingContract;
    string public getBalanceFuncSignature;

     
    mapping(address => bool) public externalLockers;
     
    mapping(address     => bool) public registrar;

     
    function initialize(
        Avatar _avatar,
        uint256 _reputationReward,
        uint256 _claimingStartTime,
        uint256 _claimingEndTime,
        uint256 _redeemEnableTime,
        address _externalLockingContract,
        string calldata _getBalanceFuncSignature)
    external
    {
        require(_claimingEndTime > _claimingStartTime, "_claimingEndTime should be greater than _claimingStartTime");
        externalLockingContract = _externalLockingContract;
        getBalanceFuncSignature = _getBalanceFuncSignature;
        super._initialize(
        _avatar,
        _reputationReward,
        _claimingStartTime,
        _claimingEndTime,
        _redeemEnableTime,
        1);
    }

     
    function claim(address _beneficiary) public returns(bytes32) {
        require(avatar != Avatar(0), "should initialize first");
        address beneficiary;
        if (_beneficiary == address(0)) {
            beneficiary = msg.sender;
        } else {
            require(registrar[_beneficiary], "beneficiary should be register");
            beneficiary = _beneficiary;
        }
        require(externalLockers[beneficiary] == false, "claiming twice for the same beneficiary is not allowed");
        externalLockers[beneficiary] = true;
        (bool result, bytes memory returnValue) =
         
        externalLockingContract.call(abi.encodeWithSignature(getBalanceFuncSignature, beneficiary));
        require(result, "call to external contract should succeed");
        uint256 lockedAmount;
         
        assembly {
            lockedAmount := mload(add(returnValue, 0x20))
        }
        return super._lock(lockedAmount, 1, beneficiary, 1, 1);
    }

    
    function register() public {
        registrar[msg.sender] = true;
        emit Register(msg.sender);
    }
}

 

pragma solidity ^0.5.4;


 
contract DxLockMgnForRep is ExternalLocking4Reputation {
    constructor() public {}
}

 

pragma solidity ^0.5.4;

interface PriceOracleInterface {

    function getPrice(address token) external view returns (uint, uint);

}

 

pragma solidity ^0.5.4;





 

contract LockingToken4Reputation is Locking4Reputation {
    using SafeERC20 for address;

    PriceOracleInterface public priceOracleContract;
     
    mapping(bytes32   => address) public lockedTokens;

    event LockToken(bytes32 indexed _lockingId, address indexed _token, uint256 _numerator, uint256 _denominator);

     
    function initialize(
        Avatar _avatar,
        uint256 _reputationReward,
        uint256 _lockingStartTime,
        uint256 _lockingEndTime,
        uint256 _redeemEnableTime,
        uint256 _maxLockingPeriod,
        PriceOracleInterface _priceOracleContract)
    external
    {
        priceOracleContract = _priceOracleContract;
        super._initialize(
        _avatar,
        _reputationReward,
        _lockingStartTime,
        _lockingEndTime,
        _redeemEnableTime,
        _maxLockingPeriod);
    }

     
    function release(address _beneficiary, bytes32 _lockingId) public returns(bool) {
        uint256 amount = super._release(_beneficiary, _lockingId);
        lockedTokens[_lockingId].safeTransfer(_beneficiary, amount);

        return true;
    }

     
    function lock(uint256 _amount, uint256 _period, address _token) public returns(bytes32 lockingId) {

        uint256 numerator;
        uint256 denominator;

        (numerator, denominator) = priceOracleContract.getPrice(_token);

        require(numerator > 0, "numerator should be > 0");
        require(denominator > 0, "denominator should be > 0");

        _token.safeTransferFrom(msg.sender, address(this), _amount);

        lockingId = super._lock(_amount, _period, msg.sender, numerator, denominator);

        lockedTokens[lockingId] = _token;

        emit LockToken(lockingId, _token, numerator, denominator);
    }
}

 

pragma solidity ^0.5.4;


 
contract DxLockWhitelisted4Rep is LockingToken4Reputation {
     
    constructor() public {}
}

 

pragma solidity ^0.5.4;




 


contract Auction4Reputation {
    using SafeMath for uint256;
    using SafeERC20 for address;

    event Bid(address indexed _bidder, uint256 indexed _auctionId, uint256 _amount);
    event Redeem(uint256 indexed _auctionId, address indexed _beneficiary, uint256 _amount);

    struct Auction {
        uint256 totalBid;
         
        mapping(address=>uint) bids;
    }

     
    mapping(uint=>Auction) public auctions;

    Avatar public avatar;
    uint256 public reputationRewardLeft;
    uint256 public auctionsEndTime;
    uint256 public auctionsStartTime;
    uint256 public numberOfAuctions;
    uint256 public auctionReputationReward;
    uint256 public auctionPeriod;
    uint256 public redeemEnableTime;
    IERC20 public token;
    address public wallet;

     
    function initialize(
        Avatar _avatar,
        uint256 _auctionReputationReward,
        uint256 _auctionsStartTime,
        uint256 _auctionPeriod,
        uint256 _numberOfAuctions,
        uint256 _redeemEnableTime,
        IERC20 _token,
        address _wallet)
    external
    {
        require(avatar == Avatar(0), "can be called only one time");
        require(_avatar != Avatar(0), "avatar cannot be zero");
        require(_numberOfAuctions > 0, "number of auctions cannot be zero");
         
        require(_auctionPeriod > 15, "auctionPeriod should be > 15");
        auctionPeriod = _auctionPeriod;
        auctionsEndTime = _auctionsStartTime + _auctionPeriod.mul(_numberOfAuctions);
        require(_redeemEnableTime >= auctionsEndTime, "_redeemEnableTime >= auctionsEndTime");
        token = _token;
        avatar = _avatar;
        auctionsStartTime = _auctionsStartTime;
        numberOfAuctions = _numberOfAuctions;
        wallet = _wallet;
        auctionReputationReward = _auctionReputationReward;
        reputationRewardLeft = _auctionReputationReward.mul(_numberOfAuctions);
        redeemEnableTime = _redeemEnableTime;
    }

     
    function redeem(address _beneficiary, uint256 _auctionId) public returns(uint256 reputation) {
         
        require(now > redeemEnableTime, "now > redeemEnableTime");
        Auction storage auction = auctions[_auctionId];
        uint256 bid = auction.bids[_beneficiary];
        require(bid > 0, "bidding amount should be > 0");
        auction.bids[_beneficiary] = 0;
        uint256 repRelation = bid.mul(auctionReputationReward);
        reputation = repRelation.div(auction.totalBid);
         
        reputationRewardLeft = reputationRewardLeft.sub(reputation);
        require(
        ControllerInterface(avatar.owner())
        .mintReputation(reputation, _beneficiary, address(avatar)), "mint reputation should succeed");
        emit Redeem(_auctionId, _beneficiary, reputation);
    }

     
    function bid(uint256 _amount, uint256 _auctionId) public returns(uint256 auctionId) {
        require(_amount > 0, "bidding amount should be > 0");
         
        require(now < auctionsEndTime, "bidding should be within the allowed bidding period");
         
        require(now >= auctionsStartTime, "bidding is enable only after bidding auctionsStartTime");
        address(token).safeTransferFrom(msg.sender, address(this), _amount);
         
        auctionId = (now - auctionsStartTime) / auctionPeriod;
        require(auctionId == _auctionId, "auction is not active");
        Auction storage auction = auctions[auctionId];
        auction.totalBid = auction.totalBid.add(_amount);
        auction.bids[msg.sender] = auction.bids[msg.sender].add(_amount);
        emit Bid(msg.sender, auctionId, _amount);
    }

     
    function getBid(address _bidder, uint256 _auctionId) public view returns(uint256) {
        return auctions[_auctionId].bids[_bidder];
    }

     
    function transferToWallet() public {
       
        require(now > auctionsEndTime, "now > auctionsEndTime");
        uint256 tokenBalance = token.balanceOf(address(this));
        address(token).safeTransfer(wallet, tokenBalance);
    }

}

 

pragma solidity ^0.5.4;


 
contract DxGenAuction4Rep is Auction4Reputation {
    constructor() public {}
}

 

pragma solidity ^0.5.4;


interface DxToken4RepInterface {
    function claim(address _beneficiary) external returns(bytes32);
    function redeem(address _beneficiary) external returns(uint256 reputation);
    
}

 

pragma solidity ^0.5.4;






contract DxDaoClaimRedeemHelper {
    DxToken4RepInterface public dxLER;
    DxToken4RepInterface public dxLMR;
    DxToken4RepInterface public dxLWR;
    DxGenAuction4Rep public dxGAR;

    constructor (
        DxToken4RepInterface _dxLER,
        DxToken4RepInterface _dxLMR,
        DxToken4RepInterface _dxLWR,
        DxGenAuction4Rep _dxGAR
    ) public {
        require(address(_dxLER) != address(0));
        require(address(_dxLMR) != address(0));
        require(address(_dxLWR) != address(0));
        require(address(_dxGAR) != address(0));
        dxLER = _dxLER;
        dxLMR = _dxLMR;
        dxLWR = _dxLWR;
        dxGAR = _dxGAR;
    }

    enum DxTokenContracts4Rep {
        dxLER,
        dxLMR,
        dxLWR,
        dxGAR
    }

     
    function claimAll(
        address[] calldata userAddresses, 
        DxTokenContracts4Rep mapIdx
    ) 
        external 
        returns(bytes32[] memory) 
    {
        require(uint(mapIdx) < 3, "mapIdx cannot be greater than 2");

        DxToken4RepInterface claimingContract;

        if (mapIdx == DxTokenContracts4Rep.dxLER) {
            claimingContract = dxLER;
        } else if (mapIdx == DxTokenContracts4Rep.dxLMR) {
            claimingContract = dxLMR;
        } else if (mapIdx == DxTokenContracts4Rep.dxLWR) {
            claimingContract = dxLWR;
        }

        uint length = userAddresses.length;

        bytes32[] memory returnArray = new bytes32[](length);

        for (uint i = 0; i < length; i++) {
            returnArray[i] = claimingContract.claim(userAddresses[i]);
        }

        return returnArray;
    }

     
    function redeemAll(
        address[] calldata userAddresses, 
        DxTokenContracts4Rep mapIdx
    ) 
        external 
        returns(uint256[] memory) 
    {        
        require(uint(mapIdx) < 3, "mapIdx cannot be greater than 2");

        DxToken4RepInterface redeemingContract;

        if (mapIdx == DxTokenContracts4Rep.dxLER) {
            redeemingContract = dxLER;
        } else if (mapIdx == DxTokenContracts4Rep.dxLMR) {
            redeemingContract = dxLMR;
        } else if (mapIdx == DxTokenContracts4Rep.dxLWR) {
            redeemingContract = dxLWR;
        }

        uint length = userAddresses.length;

        uint256[] memory returnArray = new uint256[](length);

        for (uint i = 0; i < length; i++) {
            returnArray[i] = redeemingContract.redeem(userAddresses[i]);
        }

        return returnArray;
    }

     
    function redeemAllGAR(
        address[] calldata userAddresses, 
        uint256[] calldata auctionIndices
    ) 
        external 
        returns(uint256[] memory) 
    {        
        require(userAddresses.length == auctionIndices.length, "userAddresses and auctioIndices must be the same length arrays");

        uint length = userAddresses.length;

        uint256[] memory returnArray = new uint256[](length);

        for (uint i = 0; i < length; i++) {
            returnArray[i] = dxGAR.redeem(userAddresses[i], auctionIndices[i]);
        }

        return returnArray;
    }
}