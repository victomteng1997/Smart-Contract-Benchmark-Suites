 

pragma solidity ^0.4.21;

 

interface P4RTYRelay {
     
    function relay(address beneficiary, uint256 tokenAmount) external;
}

 

 
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

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 

contract P4 is Ownable {


     

     
    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

     
    modifier onlyStronghands {
        require(myDividends(true) > 0);
        _;
    }


     

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy,
        uint timestamp,
        uint256 price
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned,
        uint timestamp,
        uint256 price
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

     
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );


     

    string public name = "P4";
    string public symbol = "P4";
    uint8 constant public decimals = 18;

     
    uint8 constant internal entryFee_ = 15;

     
    uint8 constant internal transferFee_ = 1;

     
    uint8 constant internal exitFee_ = 5;

     
    uint8 constant internal refferalFee_ = 30;

     
    uint8 constant internal maintenanceFee = 20;
    address internal maintenanceAddress;

    uint256 constant internal tokenRatio_ = 1000;
    uint256 constant internal magnitude = 2 ** 64;

     
    uint256 public stakingRequirement = 100e18;


     

     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
     
    mapping(address => address) public referrals;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;

    P4RTYRelay public relay;


     

    constructor(address relayAddress) Ownable() public {
        updateRelay(relayAddress);
         
        updateMaintenanceAddress(msg.sender);
    }

    function updateRelay (address relayAddress) onlyOwner public {
         
        relay = P4RTYRelay(relayAddress);
    }

    function updateMaintenanceAddress(address maintenance) onlyOwner public {
        maintenanceAddress = maintenance;
    }

     
    function buy(address _referredBy) public payable returns (uint256) {
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=_referredBy;
        }
        return purchaseTokens(msg.value);
    }

     
    function() payable public {
        purchaseTokens(msg.value);
    }

     
    function reinvest() onlyStronghands public {
         
        uint256 _dividends = myDividends(false);  

         
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        uint256 _tokens = purchaseTokens(_dividends);

         
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

     
    function exit() external {
         
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);

         
        withdraw();
    }

     
    function withdraw() onlyStronghands public {
         
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);  

         
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        _customerAddress.transfer(_dividends);

         
        emit onWithdraw(_customerAddress, _dividends);
    }

     
    function sell(uint256 _amountOfTokens) onlyBagholders public {
         
        address _customerAddress = msg.sender;
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

         
        if (tokenSupply_ > 0) {
             
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

         
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum, now, buyPrice());
    }


     
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders external returns (bool) {
         
        address _customerAddress = msg.sender;

         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

         
        if (myDividends(true) > 0) {
            withdraw();
        }

         
         
        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, transferFee_), 100);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);

         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);

         
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);

         
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

         
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);

         
        return true;
    }


     

     
    function totalEthereumBalance() public view returns (uint256) {
        return address(this).balance;
    }

     
    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

     
    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

     
    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

     
    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

     
    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

     
    function sellPrice() public pure returns (uint256) {
        uint256 _ethereum = tokensToEthereum_(1e18);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

        return _taxedEthereum;

    }

     
    function buyPrice() public pure returns (uint256) {
        uint256 _ethereum = tokensToEthereum_(1e18);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, entryFee_), 100);
        uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);

        return _taxedEthereum;

    }

     
    function calculateTokensReceived(uint256 _ethereumToSpend) public pure returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, entryFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);

        return _amountOfTokens;
    }

     
    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }


     

     
    function purchaseTokens(uint256 _incomingEthereum) internal returns (uint256) {
         
        address _customerAddress = msg.sender;
        address _referredBy = referrals[msg.sender];
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_), 100);
        uint256 _maintenance = SafeMath.div(SafeMath.mul(_undividedDividends,maintenanceFee),100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, refferalFee_), 100);
         
        uint256 _dividends = SafeMath.sub(_undividedDividends, SafeMath.add(_referralBonus,_maintenance));
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
        uint256 _tokenAllocation = SafeMath.div(_incomingEthereum,2);

         
         
         
         
        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

         
        referralBalance_[maintenanceAddress] = SafeMath.add(referralBalance_[maintenanceAddress], _maintenance);

         
        if (
         
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != _customerAddress &&

             
             
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
             
             
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

         
        if (tokenSupply_ > 0) {
             
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

             
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);

             
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
        } else {
             
            tokenSupply_ = _amountOfTokens;
        }

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

         
         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

         
         
        relay.relay(maintenanceAddress,_tokenAllocation);
        relay.relay(_customerAddress,_tokenAllocation);

         
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy, now, buyPrice());

        return _amountOfTokens;
    }

     
    function ethereumToTokens_(uint256 _ethereum) internal pure returns (uint256) {
        return SafeMath.mul(_ethereum, tokenRatio_);
    }

     
    function tokensToEthereum_(uint256 _tokens) internal pure returns (uint256) {
        return SafeMath.div(_tokens, tokenRatio_);
    }

}