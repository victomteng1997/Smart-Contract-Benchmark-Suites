 

 

pragma solidity ^0.4.24;

 


interface ITokenController {
     
     
     
    function proxyPayment(address _owner) external payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) external returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) external returns(bool);
}

 

pragma solidity ^0.4.24;

 

 
 
 
 
 
 
 


contract Controlled {
     
     
    modifier onlyController {
        require(msg.sender == controller);
        _;
    }

    address public controller;

    function Controlled()  public { controller = msg.sender;}

     
     
    function changeController(address _newController) onlyController  public {
        controller = _newController;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 _amount,
        address _token,
        bytes _data
    ) public;
}

 
 
 
contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = "MMT_0.1";  


     
     
     
    struct Checkpoint {

         
        uint128 fromBlock;

         
        uint128 value;
    }

     
     
    MiniMeToken public parentToken;

     
     
    uint public parentSnapShotBlock;

     
    uint public creationBlock;

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    Checkpoint[] totalSupplyHistory;

     
    bool public transfersEnabled;

     
    MiniMeTokenFactory public tokenFactory;

 
 
 

     
     
     
     
     
     
     
     
     
     
     
     
     
    function MiniMeToken(
        MiniMeTokenFactory _tokenFactory,
        MiniMeToken _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    )  public
    {
        tokenFactory = _tokenFactory;
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = _parentToken;
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


 
 
 

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            if (allowed[_from][msg.sender] < _amount)
                return false;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount) internal returns(bool) {
        if (_amount == 0) {
            return true;
        }
        require(parentSnapShotBlock < block.number);
         
        require((_to != 0) && (_to != address(this)));
         
         
        var previousBalanceFrom = balanceOfAt(_from, block.number);
        if (previousBalanceFrom < _amount) {
            return false;
        }
         
        if (isContract(controller)) {
             
            require(ITokenController(controller).onTransfer(_from, _to, _amount) == true);
        }
         
         
        updateValueAtNow(balances[_from], previousBalanceFrom - _amount);
         
         
        var previousBalanceTo = balanceOfAt(_to, block.number);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(balances[_to], previousBalanceTo + _amount);
         
        Transfer(_from, _to, _amount);
        return true;
    }

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

         
        if (isContract(controller)) {
             
            require(ITokenController(controller).onApprove(msg.sender, _spender, _amount) == true);
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(ApproveAndCallFallBack _spender, uint256 _amount, bytes _extraData) public returns (bool success) {
        require(approve(_spender, _amount));

        _spender.receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

     
     
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint) {

         
         
         
         
         
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                 
                return 0;
            }

         
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

         
         
         
         
         
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

         
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

 
 
 

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
    ) public returns(MiniMeToken)
    {
        uint256 snapshot = _snapshotBlock == 0 ? block.number - 1 : _snapshotBlock;

        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            snapshot,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
        );

        cloneToken.changeController(msg.sender);

         
        NewCloneToken(address(cloneToken), snapshot);
        return cloneToken;
    }

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint _amount) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) onlyController public {
        transfersEnabled = _transfersEnabled;
    }

 
 
 

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) constant internal returns (uint) {
        if (checkpoints.length == 0)
            return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock)
            return 0;

         
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = uint128(_value);
        }
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0)
            return false;

        assembly {
            size := extcodesize(_addr)
        }

        return size>0;
    }

     
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function () external payable {
        require(isContract(controller));
         
        require(ITokenController(controller).proxyPayment.value(msg.value)(msg.sender) == true);
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) onlyController public {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

 
 
 
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


 
 
 

 
 
 
contract MiniMeTokenFactory {

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        MiniMeToken _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken)
    {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
        );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

 

 
 

pragma solidity ^0.4.24;


 
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

 

pragma solidity ^0.4.24;

 
interface IERC777Recipient {
     
    function tokensReceived(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _data,
        bytes _operatorData
    ) external;
}

 

pragma solidity ^0.4.24;

 
 





pragma solidity ^0.4.24;

contract Token is Controlled {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;

    string public name;
    uint8 public decimals;
    string public symbol;
    bool public transfersEnabled;

    string private constant ERROR_NULL_ADDRESS = "NULL_ADDRESS_REJECTED";
    string private constant ERROR_CONTROLLER = "CONTROLLER_REJECTED";

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
    event Sent(
      address indexed _operator, address indexed _from, address indexed _to,
      uint256 _amount, bytes _data, bytes _operatorData
    );

    constructor(string _name, uint8 _decimals, string _symbol, bool _transfersEnabled) public {
        name = _name;
        decimals = _decimals;
        symbol = _symbol;
        transfersEnabled = _transfersEnabled;
    }

     
     
     
    function () external payable {
        require(isContract(controller), "CONTROLLER_IS_NOT_CONTRACT");
        require(ITokenController(controller).proxyPayment.value(msg.value)(msg.sender) == true, ERROR_CONTROLLER);
    }

     
    modifier transferable() {
        require(msg.sender == controller || transfersEnabled, "NON_TRANSFERABLE");
        _;
    }

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function generateTokens(address _to, uint256 _amount) public onlyController returns (bool) {
        _mint(_to, _amount);
        return true;
    }

     
    function destroyTokens(address _from, uint256 _amount) public onlyController returns (bool) {
        _burn(_from, _amount);
        return true;
    }

     
     
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

     
    function transfer(address to, uint256 value) public transferable returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public transferable returns (bool) {
        _transfer(from, to, value);
         
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function approve(address spender, uint256 value) public transferable returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public transferable returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public transferable returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function send(address to, uint256 value, bytes data) external {
        _transfer(msg.sender, to, value);
        emit Sent(msg.sender, msg.sender, to, value, data, "");
        if(isContract(to))
          IERC777Recipient(to).tokensReceived(msg.sender, msg.sender, to, value, data, "");
    }

     
    function _transfer(address _from, address _to, uint256 _amount) internal {
         
        if (isContract(controller)) {
            require(ITokenController(controller).onTransfer(_from, _to, _amount) == true, ERROR_CONTROLLER);
        }

        require(_to != address(0), ERROR_NULL_ADDRESS);

        _balances[_from] = _balances[_from].sub(_amount);
        _balances[_to] = _balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }

     
    function _approve(address _owner, address _spender, uint256 _amount) internal {
         
        if (isContract(controller)) {
            require(ITokenController(controller).onApprove(_owner, _spender, _amount) == true, ERROR_CONTROLLER);
        }

        require(_spender != address(0), ERROR_NULL_ADDRESS);
        require(_owner != address(0), ERROR_NULL_ADDRESS);

        _allowed[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0), ERROR_NULL_ADDRESS);

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), ERROR_NULL_ADDRESS);

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
     
     
    function isContract(address _addr) internal view returns(bool) {
        uint size;
        if (_addr == 0)
            return false;

        assembly {
            size := extcodesize(_addr)
        }

        return size>0;
    }
}