 

pragma solidity ^0.5.8;

library SharedStructs {
    struct DIDHolder {
        uint256 balance;
        uint256 netContributionsDID;     
        uint256 DIDHoldersIndex;
        uint256 weiInvested;
        uint256 tasksCompleted;
    }
}


contract Approvable {

    mapping(address => bool) public approved;

    constructor () public {
        approved[msg.sender] = true;
    }

    function approve(address _address) public onlyApproved {
        require(_address != address(0));
        approved[_address] = true;
    }

    function revokeApproval(address _address) public onlyApproved {
        require(_address != address(0));
        approved[_address] = false;
    }

    modifier onlyApproved() {
        require(approved[msg.sender]);
        _;
    }
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }


  function percent(uint numerator, uint denominator, uint precision) public pure
  returns(uint quotient) {

     
    uint _numerator  = numerator * 10 ** (precision + 1);

     
    uint _quotient =  ((_numerator / denominator) + 5) / 10;
    return _quotient;
  }

}














contract DIDToken is Approvable {

    using SafeMath for uint256;

    event LogIssueDID(address indexed to, uint256 numDID);
    event LogDecrementDID(address indexed to, uint256 numDID);
    event LogDecrementDIDFromContributions(address indexed to, uint256 numDIDFromContributions);
    event LogExchangeDIDForEther(address indexed to, uint256 numDID);
    event LogInvestEtherForDID(address indexed to, uint256 numWei);

    address[] public DIDHoldersArray;

    address public DistenseAddress;

    uint256 public investmentLimitAggregate  = 100000 ether;   
    uint256 public investmentLimitAddress = 100 ether;   
    uint256 public investedAggregate = 1 ether;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => SharedStructs.DIDHolder) public DIDHolders;

    constructor () public {
        name = "Distense DID";
        symbol = "DID";
        totalSupply = 0;
        decimals = 18;
    }

    function issueDID(address _recipient, uint256 _numDID) public onlyApproved returns (bool) {
        require(_recipient != address(0));
        require(_numDID > 0);

        _numDID = _numDID * 1 ether;
        totalSupply = SafeMath.add(totalSupply, _numDID);
        
        uint256 balance = DIDHolders[_recipient].balance;
        DIDHolders[_recipient].balance = SafeMath.add(balance, _numDID);

         
        if (DIDHolders[_recipient].DIDHoldersIndex == 0) {
            uint256 index = DIDHoldersArray.push(_recipient) - 1;
            DIDHolders[_recipient].DIDHoldersIndex = index;
        }

        emit LogIssueDID(_recipient, _numDID);

        return true;
    }

    function decrementDID(address _address, uint256 _numDID) external onlyApproved returns (uint256) {
        require(_address != address(0));
        require(_numDID > 0);

        uint256 numDID = _numDID * 1 ether;
        require(SafeMath.sub(DIDHolders[_address].balance, numDID) >= 0);
        require(SafeMath.sub(totalSupply, numDID ) >= 0);

        totalSupply = SafeMath.sub(totalSupply, numDID);
        DIDHolders[_address].balance = SafeMath.sub(DIDHolders[_address].balance, numDID);

         
         
        if (DIDHolders[_address].balance == 0) {
            deleteDIDHolderWhenBalanceZero(_address);
        }

        emit LogDecrementDID(_address, numDID);

        return DIDHolders[_address].balance;
    }

    function decrementDIDFromContributions(address _address, uint256 _numDIDFromContributions) external onlyApproved returns (uint256) {
        require(_address != address(0));
        require(_numDIDFromContributions > 0);

        uint256 numDIDFromContributions = _numDIDFromContributions * 1 ether;
        require(SafeMath.sub(DIDHolders[_address].netContributionsDID, numDIDFromContributions) >= 0);
        require(SafeMath.sub(totalSupply, numDIDFromContributions) >= 0);

        totalSupply = SafeMath.sub(totalSupply, numDIDFromContributions);
        DIDHolders[_address].netContributionsDID = SafeMath.sub(DIDHolders[_address].netContributionsDID, numDIDFromContributions);

        emit LogDecrementDIDFromContributions(_address, numDIDFromContributions);

        return DIDHolders[_address].netContributionsDID;
    }

    function exchangeDIDForEther(uint256 _numDIDToExchange)
        external
    returns (uint256) {

        uint256 numDIDToExchange = _numDIDToExchange * 1 ether;
        uint256 netContributionsDID = getNumContributionsDID(msg.sender);
        require(netContributionsDID >= numDIDToExchange);

        Distense distense = Distense(DistenseAddress);
        uint256 DIDPerEther = distense.getParameterValueByTitle(distense.didPerEtherParameterTitle());

        require(numDIDToExchange < totalSupply);

        uint256 numWeiToIssue = calculateNumWeiToIssue(numDIDToExchange, DIDPerEther);
        address contractAddress = address(this);
        require(contractAddress.balance >= numWeiToIssue, "DIDToken contract must have sufficient wei");

         
        DIDHolders[msg.sender].balance = SafeMath.sub(DIDHolders[msg.sender].balance, numDIDToExchange);
        DIDHolders[msg.sender].netContributionsDID = SafeMath.sub(DIDHolders[msg.sender].netContributionsDID, numDIDToExchange);
        totalSupply = SafeMath.sub(totalSupply, numDIDToExchange);

        msg.sender.transfer(numWeiToIssue);

        if (DIDHolders[msg.sender].balance == 0) {
            deleteDIDHolderWhenBalanceZero(msg.sender);
        }
        emit LogExchangeDIDForEther(msg.sender, numDIDToExchange);

        return DIDHolders[msg.sender].balance;
    }

    function investEtherForDID() external payable returns (uint256) {
        require(getNumWeiAddressMayInvest(msg.sender) >= msg.value);
        require(investedAggregate < investmentLimitAggregate);

        Distense distense = Distense(DistenseAddress);
        uint256 DIDPerEther = SafeMath.div(distense.getParameterValueByTitle(distense.didPerEtherParameterTitle()), 1 ether);

        uint256 numDIDToIssue = calculateNumDIDToIssue(msg.value, DIDPerEther);
        require(DIDHolders[msg.sender].netContributionsDID >= numDIDToIssue);
        totalSupply = SafeMath.add(totalSupply, numDIDToIssue);
        DIDHolders[msg.sender].balance = SafeMath.add(DIDHolders[msg.sender].balance, numDIDToIssue);
        DIDHolders[msg.sender].netContributionsDID = SafeMath.sub(DIDHolders[msg.sender].netContributionsDID, numDIDToIssue);

        DIDHolders[msg.sender].weiInvested += msg.value;
        investedAggregate = investedAggregate + msg.value;

        emit LogIssueDID(msg.sender, numDIDToIssue);
        emit LogInvestEtherForDID(msg.sender, msg.value);

        return DIDHolders[msg.sender].balance;
    }

    function incrementDIDFromContributions(address _contributor, uint256 _reward) onlyApproved public {
        uint256 weiReward = _reward * 1 ether;
        DIDHolders[_contributor].netContributionsDID = SafeMath.add(DIDHolders[_contributor].netContributionsDID, weiReward);
    }

    function incrementTasksCompleted(address _contributor) onlyApproved public returns (bool) {
        DIDHolders[_contributor].tasksCompleted++;
        return true;
    }

    function pctDIDOwned(address _address) external view returns (uint256) {
        return SafeMath.percent(DIDHolders[_address].balance, totalSupply, 20);
    }

    function getNumWeiAddressMayInvest(address _contributor) public view returns (uint256) {

        uint256 DIDFromContributions = DIDHolders[_contributor].netContributionsDID;
        require(DIDFromContributions > 0);
        uint256 netUninvestedEther = SafeMath.sub(investmentLimitAddress, DIDHolders[_contributor].weiInvested);
        require(netUninvestedEther > 0);

        Distense distense = Distense(DistenseAddress);
        uint256 DIDPerEther = distense.getParameterValueByTitle(distense.didPerEtherParameterTitle());

        return (DIDFromContributions * 1 ether) / DIDPerEther;
    }

    function rewardContributor(address _contributor, uint256 _reward) external onlyApproved returns (bool) {
        uint256 reward = SafeMath.div(_reward, 1 ether);
        bool issued = issueDID(_contributor, reward);
        if (issued) incrementDIDFromContributions(_contributor, reward);
        incrementTasksCompleted(_contributor);
        return true;
    }

    function getWeiAggregateMayInvest() public view returns (uint256) {
        return SafeMath.sub(investmentLimitAggregate, investedAggregate);
    }

    function getNumDIDHolders() external view returns (uint256) {
        return DIDHoldersArray.length;
    }

    function getAddressBalance(address _address) public view returns (uint256) {
        return DIDHolders[_address].balance;
    }

    function getNumContributionsDID(address _address) public view returns (uint256) {
        return DIDHolders[_address].netContributionsDID;
    }

    function getWeiInvested(address _address) public view returns (uint256) {
        return DIDHolders[_address].weiInvested;
    }

    function calculateNumDIDToIssue(uint256 msgValue, uint256 DIDPerEther) public pure returns (uint256) {
        return SafeMath.mul(msgValue, DIDPerEther);
    }

    function calculateNumWeiToIssue(uint256 _numDIDToExchange, uint256 _DIDPerEther) public pure returns (uint256) {
        _numDIDToExchange = _numDIDToExchange * 1 ether;
        return SafeMath.div(_numDIDToExchange, _DIDPerEther);
    }

    function deleteDIDHolderWhenBalanceZero(address holder) internal {
        if (DIDHoldersArray.length > 1) {
            address lastElement = DIDHoldersArray[DIDHoldersArray.length - 1];
            DIDHoldersArray[DIDHolders[holder].DIDHoldersIndex] = lastElement;
            DIDHoldersArray.length--;
            delete DIDHolders[holder];
        }
    }

    function deleteDIDHolder(address holder) public onlyApproved {
        if (DIDHoldersArray.length > 1) {
            address lastElement = DIDHoldersArray[DIDHoldersArray.length - 1];
            DIDHoldersArray[DIDHolders[holder].DIDHoldersIndex] = lastElement;
            DIDHoldersArray.length--;
            delete DIDHolders[holder];
        }
    }

    function setDistenseAddress(address _distenseAddress) onlyApproved public  {
        DistenseAddress = _distenseAddress;
    }

}



contract Distense is Approvable {

    using SafeMath for uint256;

    address public DIDTokenAddress;

     

     
    bytes32[] public parameterTitles;

    struct Parameter {
        bytes32 title;
        uint256 value;
        mapping(address => Vote) votes;
    }

    struct Vote {
        address voter;
        uint256 lastVoted;
    }

    mapping(bytes32 => Parameter) public parameters;

    Parameter public votingIntervalParameter;
    bytes32 public votingIntervalParameterTitle = 'votingInterval';

    Parameter public pctDIDToDetermineTaskRewardParameter;
    bytes32 public pctDIDToDetermineTaskRewardParameterTitle = 'pctDIDToDetermineTaskReward';

    Parameter public pctDIDRequiredToMergePullRequest;
    bytes32 public pctDIDRequiredToMergePullRequestTitle = 'pctDIDRequiredToMergePullRequest';

    Parameter public maxRewardParameter;
    bytes32 public maxRewardParameterTitle = 'maxReward';

    Parameter public numDIDRequiredToApproveVotePullRequestParameter;
    bytes32 public numDIDRequiredToApproveVotePullRequestParameterTitle = 'numDIDReqApproveVotePullRequest';

    Parameter public numDIDRequiredToTaskRewardVoteParameter;
    bytes32 public numDIDRequiredToTaskRewardVoteParameterTitle = 'numDIDRequiredToTaskRewardVote';

    Parameter public minNumberOfTaskRewardVotersParameter;
    bytes32 public minNumberOfTaskRewardVotersParameterTitle = 'minNumberOfTaskRewardVoters';

    Parameter public numDIDRequiredToAddTaskParameter;
    bytes32 public numDIDRequiredToAddTaskParameterTitle = 'numDIDRequiredToAddTask';

    Parameter public defaultRewardParameter;
    bytes32 public defaultRewardParameterTitle = 'defaultReward';

    Parameter public didPerEtherParameter;
    bytes32 public didPerEtherParameterTitle = 'didPerEther';

    Parameter public votingPowerLimitParameter;
    bytes32 public votingPowerLimitParameterTitle = 'votingPowerLimit';

    event LogParameterValueUpdate(bytes32 title, uint256 value);

    constructor () public {

         
         
         

         
        pctDIDToDetermineTaskRewardParameter = Parameter({
            title : pctDIDToDetermineTaskRewardParameterTitle,
             
             
            value: 15 * 1 ether
        });
        parameters[pctDIDToDetermineTaskRewardParameterTitle] = pctDIDToDetermineTaskRewardParameter;
        parameterTitles.push(pctDIDToDetermineTaskRewardParameterTitle);


        pctDIDRequiredToMergePullRequest = Parameter({
            title : pctDIDRequiredToMergePullRequestTitle,
            value: 10 * 1 ether
        });
        parameters[pctDIDRequiredToMergePullRequestTitle] = pctDIDRequiredToMergePullRequest;
        parameterTitles.push(pctDIDRequiredToMergePullRequestTitle);


        votingIntervalParameter = Parameter({
            title : votingIntervalParameterTitle,
            value: 1296000 * 1 ether   
        });
        parameters[votingIntervalParameterTitle] = votingIntervalParameter;
        parameterTitles.push(votingIntervalParameterTitle);


        maxRewardParameter = Parameter({
            title : maxRewardParameterTitle,
            value: 2000 * 1 ether
        });
        parameters[maxRewardParameterTitle] = maxRewardParameter;
        parameterTitles.push(maxRewardParameterTitle);


        numDIDRequiredToApproveVotePullRequestParameter = Parameter({
            title : numDIDRequiredToApproveVotePullRequestParameterTitle,
             
            value: 100 * 1 ether
        });
        parameters[numDIDRequiredToApproveVotePullRequestParameterTitle] = numDIDRequiredToApproveVotePullRequestParameter;
        parameterTitles.push(numDIDRequiredToApproveVotePullRequestParameterTitle);


         
         

         
         

         
        numDIDRequiredToTaskRewardVoteParameter = Parameter({
            title : numDIDRequiredToTaskRewardVoteParameterTitle,
             
            value: 100 * 1 ether
        });
        parameters[numDIDRequiredToTaskRewardVoteParameterTitle] = numDIDRequiredToTaskRewardVoteParameter;
        parameterTitles.push(numDIDRequiredToTaskRewardVoteParameterTitle);


        minNumberOfTaskRewardVotersParameter = Parameter({
            title : minNumberOfTaskRewardVotersParameterTitle,
             
            value: 7 * 1 ether
        });
        parameters[minNumberOfTaskRewardVotersParameterTitle] = minNumberOfTaskRewardVotersParameter;
        parameterTitles.push(minNumberOfTaskRewardVotersParameterTitle);


        numDIDRequiredToAddTaskParameter = Parameter({
            title : numDIDRequiredToAddTaskParameterTitle,
             
            value: 100 * 1 ether
        });
        parameters[numDIDRequiredToAddTaskParameterTitle] = numDIDRequiredToAddTaskParameter;
        parameterTitles.push(numDIDRequiredToAddTaskParameterTitle);


        defaultRewardParameter = Parameter({
            title : defaultRewardParameterTitle,
             
            value: 100 * 1 ether
        });
        parameters[defaultRewardParameterTitle] = defaultRewardParameter;
        parameterTitles.push(defaultRewardParameterTitle);


        didPerEtherParameter = Parameter({
            title : didPerEtherParameterTitle,
             
            value: 200 * 1 ether
        });
        parameters[didPerEtherParameterTitle] = didPerEtherParameter;
        parameterTitles.push(didPerEtherParameterTitle);

        votingPowerLimitParameter = Parameter({
            title : votingPowerLimitParameterTitle,
             
            value: 20 * 1 ether
        });
        parameters[votingPowerLimitParameterTitle] = votingPowerLimitParameter;
        parameterTitles.push(votingPowerLimitParameterTitle);

    }

    function getParameterValueByTitle(bytes32 _title) public view returns (uint256) {
        return parameters[_title].value;
    }

     
    function voteOnParameter(bytes32 _title, int256 _voteValue)
        public
        votingIntervalReached(msg.sender, _title)
        returns
    (uint256) {

        DIDToken didToken = DIDToken(DIDTokenAddress);
        uint256 votersDIDPercent = didToken.pctDIDOwned(msg.sender);
        require(votersDIDPercent > 0);

        uint256 currentValue = getParameterValueByTitle(_title);

         
         
        uint256 votingPowerLimit = getParameterValueByTitle(votingPowerLimitParameterTitle);

        uint256 limitedVotingPower = votersDIDPercent > votingPowerLimit ? votingPowerLimit : votersDIDPercent;

        uint256 update;
        if (
            _voteValue == 1 ||   
            _voteValue == - 1 ||  
            _voteValue > int(limitedVotingPower) ||  
            _voteValue < - int(limitedVotingPower)   
        ) {
            update = (limitedVotingPower * currentValue) / (100 * 1 ether);
        } else if (_voteValue > 0) {
            update = SafeMath.div((uint(_voteValue) * currentValue), (1 ether * 100));
        } else if (_voteValue < 0) {
            int256 adjustedVoteValue = (-_voteValue);  
            update = uint((adjustedVoteValue * int(currentValue))) / (100 * 1 ether);
        } else revert();  

        if (_voteValue > 0)
            currentValue = SafeMath.add(currentValue, update);
        else
            currentValue = SafeMath.sub(currentValue, update);

        updateParameterValue(_title, currentValue);
        updateLastVotedOnParameter(_title, msg.sender);
        emit LogParameterValueUpdate(_title, currentValue);

        return currentValue;
    }

    function getParameterByTitle(bytes32 _title) public view returns (bytes32, uint256) {
        Parameter memory param = parameters[_title];
        return (param.title, param.value);
    }

    function getNumParameters() public view returns (uint256) {
        return parameterTitles.length;
    }

    function updateParameterValue(bytes32 _title, uint256 _newValue) internal returns (uint256) {
        Parameter storage parameter = parameters[_title];
        parameter.value = _newValue;
        return parameter.value;
    }

    function updateLastVotedOnParameter(bytes32 _title, address voter) internal returns (bool) {
        Parameter storage parameter = parameters[_title];
        parameter.votes[voter].lastVoted = now;
    }

    function setDIDTokenAddress(address _didTokenAddress) public onlyApproved {
        DIDTokenAddress = _didTokenAddress;
    }

    modifier votingIntervalReached(address _voter, bytes32 _title) {
        Parameter storage parameter = parameters[_title];
        uint256 lastVotedOnParameter = parameter.votes[_voter].lastVoted * 1 ether;
        require((now * 1 ether) >= lastVotedOnParameter + getParameterValueByTitle(votingIntervalParameterTitle));
        _;
    }
}