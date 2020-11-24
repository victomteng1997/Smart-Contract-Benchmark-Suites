 

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;


 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

     
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

pragma solidity ^0.5.0;




 
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

     
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;



contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

 

pragma solidity ^0.5.0;

 
library Math {
     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.12;





 
contract ERC20Migrator is Ownable {
     
    ERC20Detailed private _legacyToken;

     
    ERC20Mintable private _newToken;

     
    bool private _migrationFinished;

     
    address private _legacyDepositAddress;
    address private _newDepositAddress;

     
    mapping(address => bool) public accountMigrated;

     
    uint16 public constant ARRAY_LENGTH_LIMIT = 100;
    
    event MigrationStarted(address legacyToken, address newToken);
    event MigrationFinished(address legacyToken, address newToken);

     
    constructor(ERC20Detailed legacyToken_, address legacyDepositAddress_) public {
        require(
            address(legacyToken_) != address(0),
            "ERC20Migrator: legacy token is the zero address"
        );
        require(
            bytes(legacyToken_.symbol()).length > 0,
            "ERC20Migrator: legacyToken should be initialized"
        );
        require(
            legacyDepositAddress_ != address(0),
            "ERC20Migrator: legacyDepositAddress_ is the zero address"
        );
        _legacyToken = legacyToken_;
        _newToken = ERC20Mintable(address(0));
        _legacyDepositAddress = legacyDepositAddress_;
    }

     
    function legacyToken() external view returns (address) {
        return address(_legacyToken);
    }

     
    function newToken() external view returns (address) {
        return address(_newToken);
    }

     
    function migrationFinished() external view returns (bool) {
        return _migrationFinished;
    }

     
    function newContractAddress() external view returns (address) {
        return _newDepositAddress;
    }

     
    function legacyContractAddress() external view returns (address) {
        return _legacyDepositAddress;
    }
     
    modifier onlyMigrating() {
        require(_migrationFinished == false, "ERC20Migrator: Migration finished");
        require(address(_newToken) != address(0), "ERC20Migrator: token is not set");
        require(_newDepositAddress != address(0), "ERC20Migrator: DepositContract address is not set");
        require(_newToken.isMinter(address(this)) == true, "ERC20Migrator: im not allowed to mint");
        _;
    }

     
    function beginMigration(ERC20Mintable newToken_, address newDepositAddress_) external onlyOwner returns (bool) {
        require(address(_newToken) == address(0), "ERC20Migrator: migration already started");
        require(address(_newDepositAddress) == address(0), "ERC20Migrator: newDepositAddress set and already started");
        require(address(newToken_) != address(0), "ERC20Migrator: new token is the zero address");
        require(address(newDepositAddress_) != address(0), "ERC20Migrator: depositContractAddress is the zero address");
        require(
            address(newToken_) != address(_legacyToken),
            "ERC20Migrator: new token should not be legacy token"
        );
         
        require(newToken_.isMinter(address(this)), "ERC20Migrator: not a minter for new token");
         

        _newToken = newToken_;
        _newDepositAddress = newDepositAddress_;
        emit MigrationStarted(address(_legacyToken), address(_newToken));
        return true;
    }

     
    function mint(address account, uint256 amount) private returns (bool) {
        require(accountMigrated[account] == false, "ERC20Migrator: Account already migrated");
        accountMigrated[account] = true;
        require(_newToken.mint(account, amount), "ERC20Migrator: Error calling mint");
        return true;
    }

     
    function migrateBalance(address account) private onlyMigrating returns (bool) {
        uint256 balance = _legacyToken.balanceOf(account);
         
        if (account == _legacyDepositAddress) {
            return mint(_newDepositAddress, balance);
        }
         
        return mint(account, balance);
    }

     
    function migrateBatch(address[] memory _to) public returns (bool) {
        require(_to.length <= ARRAY_LENGTH_LIMIT, "ERC20Migrator: max array length reached");
        for (uint256 i = 0; i < _to.length; i++) {
            require(migrateBalance(_to[i]), "ERC20Migrator: batch error");
        }
        return true;
    }

     
    function finishMigration() external onlyOwner onlyMigrating {
        _migrationFinished = true;
        _newToken.renounceMinter();
        emit MigrationFinished(address(_legacyToken), address(_newToken));
    }
}