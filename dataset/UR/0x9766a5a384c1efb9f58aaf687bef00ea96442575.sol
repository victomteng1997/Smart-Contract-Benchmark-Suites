 

 

pragma solidity ^0.4.24;

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
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

contract SmartMMM is Ownable
{
    struct DepositItem {
        uint time;
        uint sum;
        uint withdrawalTime;
        uint restartIndex;
        uint invested;
        uint payments;
        uint referralPayments;
        uint cashback;
        uint referalsLevelOneCount;
        uint referalsLevelTwoCount;
        address referrerLevelOne;
        address referrerLevelTwo;
    }

    address public techSupport = 0x799358af628240603A1ce05b7D9ea211b9D64304;
    address public adsSupport = 0x8Fa6E56c844be9B96C30B72cC2a8ccF6465a99F9;

    mapping(address => DepositItem) public deposits;
    mapping(address => bool) public referrers;
    mapping(address => uint) public waitingReferrers;

    uint public referrerPrice = 70700000000000000;  
    uint public referrerBeforeEndTime = 0;
    uint public maxBalance = 0;
    uint public invested;
    uint public payments;
    uint public referralPayments;
    uint public investorsCount;
    uint[] public historyOfRestarts;

    event Deposit(address indexed from, uint256 value);
    event Withdraw(address indexed to, uint256 value);
    event PayBonus(address indexed to, uint256 value);

    constructor () public
    {
        historyOfRestarts.push(now);
    }


    function bytesToAddress(bytes source) private pure returns(address parsedAddress)
    {
        assembly {
            parsedAddress := mload(add(source,0x14))
        }
        return parsedAddress;
    }

    function getPercents(uint balance) public pure returns(uint depositPercent, uint referrerLevelOnePercent, uint referrerLevelTwoPercent, uint cashBackPercent, uint techSupportPercent, uint adsSupportPercent)
    {
        if(balance < 25 ether) return (69444444444, 90, 10, 20, 30, 60);
        else if(balance >= 25 ether && balance < 250 ether) return (104166666667, 80, 10, 20, 30, 60);
        else if(balance >= 250 ether && balance < 2500 ether ) return (138888888889, 70, 10, 20, 30, 60);
        else if(balance >= 2500 ether && balance < 10000 ether) return (173611111111, 60, 10, 20, 30, 60);
        else if(balance >= 10000 ether && balance < 20000 ether) return (138888888889, 50, 10, 15, 25, 50);
        else if(balance >= 20000 ether && balance < 30000 ether) return (104166666667, 40, 5, 15, 25, 50);
        else if(balance >= 30000 ether && balance < 40000 ether) return (69444444444, 30, 5, 10, 20, 40);
        else if(balance >= 40000 ether && balance < 50000 ether) return (55555555555, 20, 5, 5, 20, 40);
        else if(balance >= 50000 ether && balance < 60000 ether) return (416666666667, 10, 5, 5, 15, 30);
        else if(balance >= 60000 ether && balance < 70000 ether) return (277777777778, 8, 3, 3, 10, 20);
        else if(balance >= 70000 ether && balance < 100000 ether) return (138888888889, 5, 2, 2, 10, 20);
        else return (6944444444, 0, 0, 0, 10, 10);
    }

    function () public payable
    {
        uint balance = address(this).balance;
        (uint depositPercent, uint referrerLevelOnePercent, uint referrerLevelTwoPercent, uint cashBackPercent, uint techSupportPercent, uint adsSupportPercent) = getPercents(balance);

        if(msg.value == 0)
        {
            payWithdraw(msg.sender, balance, depositPercent);
            return;
        }

        if(msg.value == referrerPrice && !referrers[msg.sender] && waitingReferrers[msg.sender] == 0 && deposits[msg.sender].sum != 0)
        {
            waitingReferrers[msg.sender] = now;
        }
        else
        {
            addDeposit(msg.sender, msg.value, balance, referrerLevelOnePercent, referrerLevelTwoPercent, cashBackPercent, depositPercent, techSupportPercent, adsSupportPercent);
        }
    }

    function isNeedRestart(uint balance) public returns (bool)
    {
        if(balance < maxBalance / 100 * 30) {
            maxBalance = 0;
            return true;
        }
        return false;
    }

    function calculateNewTime(uint oldTime, uint oldSum, uint newSum, uint currentTime) public pure returns (uint)
    {
        return oldTime + newSum / (newSum + oldSum) * (currentTime - oldTime);
    }

    function calculateNewDepositSum(uint minutesBetweenRestart, uint minutesWork, uint depositSum) public pure returns (uint)
    {
        if(minutesWork > minutesBetweenRestart) minutesWork = minutesBetweenRestart;
        return (depositSum *(100-(uint(minutesWork) * 100 / minutesBetweenRestart)+7)/100);
    }

    function addDeposit(address investorAddress, uint weiAmount, uint balance, uint referrerLevelOnePercent, uint referrerLevelTwoPercent, uint cashBackPercent, uint depositPercent, uint techSupportPercent, uint adsSupportPercent) private
    {
        checkReferrer(investorAddress, weiAmount, referrerLevelOnePercent, referrerLevelTwoPercent, cashBackPercent);
        DepositItem memory deposit = deposits[investorAddress];
        if(deposit.sum == 0)
        {
            deposit.time = now;
            investorsCount++;
        }
        else
        {
            uint sum = getWithdrawSum(investorAddress, depositPercent);
            deposit.sum += sum;
            deposit.time = calculateNewTime(deposit.time, deposit.sum, weiAmount, now);
        }
        deposit.withdrawalTime = now;
        deposit.sum += weiAmount;
        deposit.restartIndex = historyOfRestarts.length - 1;
        deposit.invested += weiAmount;
        deposits[investorAddress] = deposit;

        emit Deposit(investorAddress, weiAmount);

        payToSupport(weiAmount, techSupportPercent, adsSupportPercent);

        if (maxBalance < balance) {
            maxBalance = balance;
        }
        invested += weiAmount;
    }

    function payToSupport(uint weiAmount, uint techSupportPercent, uint adsSupportPercent) private {
        techSupport.transfer(weiAmount * techSupportPercent / 1000);
        adsSupport.transfer(weiAmount * adsSupportPercent / 1000);
    }

    function checkReferrer(address investorAddress, uint weiAmount, uint referrerLevelOnePercent, uint referrerLevelTwoPercent, uint cashBackPercent) private
    {
        address referrerLevelOneAddress = deposits[investorAddress].referrerLevelOne;
        address referrerLevelTwoAddress = deposits[investorAddress].referrerLevelTwo;
        if (deposits[investorAddress].sum == 0 && msg.data.length == 20) {
            referrerLevelOneAddress = bytesToAddress(bytes(msg.data));
            if (referrerLevelOneAddress != investorAddress && referrerLevelOneAddress != address(0)) {
                if (referrers[referrerLevelOneAddress] || waitingReferrers[referrerLevelOneAddress] != 0 && (now - waitingReferrers[referrerLevelOneAddress]) >= 7 days || now <= referrerBeforeEndTime) {
                    deposits[investorAddress].referrerLevelOne = referrerLevelOneAddress;
                    deposits[referrerLevelOneAddress].referalsLevelOneCount++;
                    referrerLevelTwoAddress = deposits[referrerLevelOneAddress].referrerLevelOne;
                    if (referrerLevelTwoAddress != investorAddress && referrerLevelTwoAddress != address(0)) {
                        deposits[investorAddress].referrerLevelTwo = referrerLevelTwoAddress;
                        deposits[referrerLevelTwoAddress].referalsLevelTwoCount++;
                    }
                }
            }
        }
        if (referrerLevelOneAddress != address(0)) {
            uint cashBackBonus = weiAmount * cashBackPercent / 1000;
            uint referrerLevelOneBonus = weiAmount * referrerLevelOnePercent / 1000;

            emit PayBonus(investorAddress, cashBackBonus);
            emit PayBonus(referrerLevelOneAddress, referrerLevelOneBonus);

            referralPayments += referrerLevelOneBonus;
            deposits[referrerLevelOneAddress].referralPayments += referrerLevelOneBonus;
            referrerLevelOneAddress.transfer(referrerLevelOneBonus);

            deposits[investorAddress].cashback += cashBackBonus;
            investorAddress.transfer(cashBackBonus);

            if (referrerLevelTwoAddress != address(0)) {
                uint referrerLevelTwoBonus = weiAmount * referrerLevelTwoPercent / 1000;
                emit PayBonus(referrerLevelTwoAddress, referrerLevelTwoBonus);
                referralPayments += referrerLevelTwoBonus;
                deposits[referrerLevelTwoAddress].referralPayments += referrerLevelTwoBonus;
                referrerLevelTwoAddress.transfer(referrerLevelTwoBonus);
            }
        }
    }

    function payWithdraw(address to, uint balance, uint percent) private
    {
        require(deposits[to].sum > 0);

        if(isNeedRestart(balance))
        {
            historyOfRestarts.push(now);
        }

        uint lastRestartIndex = historyOfRestarts.length - 1;

        if(lastRestartIndex - deposits[to].restartIndex >= 1)
        {
            uint minutesBetweenRestart = (historyOfRestarts[lastRestartIndex] - historyOfRestarts[deposits[to].restartIndex]) / 1 minutes;
            uint minutesWork = (historyOfRestarts[lastRestartIndex] - deposits[to].time) / 1 minutes;
            deposits[to].sum = calculateNewDepositSum(minutesBetweenRestart, minutesWork, deposits[to].sum);
            deposits[to].restartIndex = lastRestartIndex;
            deposits[to].time = now;
        }

        uint sum = getWithdrawSum(to, percent);
        require(sum > 0);

        deposits[to].withdrawalTime = now;
        deposits[to].payments += sum;
        payments += sum;
        to.transfer(sum);

        emit Withdraw(to, sum);
    }

    function getWithdrawSum(address investorAddress, uint percent) private view returns(uint sum) {
        uint minutesCount = (now - deposits[investorAddress].withdrawalTime) / 1 minutes;
        sum = deposits[investorAddress].sum * percent / 10000000000000000 * minutesCount;
    }

    function addReferrer(address referrerAddress) onlyOwner public
    {
        referrers[referrerAddress] = true;
    }

    function setReferrerPrice(uint newPrice) onlyOwner public
    {
        referrerPrice = newPrice;
    }

    function setReferrerBeforeEndTime(uint newTime) onlyOwner public
    {
        referrerBeforeEndTime = newTime;
    }

    function getDaysAfterStart() public constant returns(uint daysAfterStart) {
        daysAfterStart = (now - historyOfRestarts[0]) / 1 days;
    }

    function getDaysAfterLastRestart() public constant returns(uint daysAfeterLastRestart) {
        daysAfeterLastRestart = (now - historyOfRestarts[historyOfRestarts.length - 1]) / 1 days;
    }
}