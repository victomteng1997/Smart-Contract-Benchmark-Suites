 

pragma solidity ^0.4.24;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

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

library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
     
     
     
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}

contract TokenTimelock {
  using SafeERC20 for IERC20;

  IERC20 private _token;
  address private _sender;
  address private _beneficiary;
  uint256 private _releaseTime;

  constructor(
    IERC20 token,
    address beneficiary,
    uint256 releaseTime
  )
    public
  {
     
    require(releaseTime > block.timestamp);
    _token = token;
    _sender = msg.sender;
    _beneficiary = beneficiary;
    _releaseTime = releaseTime;
  }

  function token() public view returns(IERC20) {
    return _token;
  }
  function sender() public view returns(address) {
    return _sender;
  }
  function beneficiary() public view returns(address) {
    return _beneficiary;
  }
  function releaseTime() public view returns(uint256) {
    return _releaseTime;
  }

  function release() public {
     
    require((msg.sender == _sender) || (msg.sender == _beneficiary), "thou shall not pass!");
    require(block.timestamp >= _releaseTime, "not yet.");

    uint256 amount = _token.balanceOf(address(this));
    require(amount > 0, "zero balance");

    _token.safeTransfer(_beneficiary, amount);
  }

  function cancel() public {
    require(msg.sender == _sender, "Only sender can do this");

    uint256 amount = _token.balanceOf(address(this));
    require(amount > 0, "zero balance");

    _token.safeTransfer(_sender, amount);
  }
}