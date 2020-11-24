 

pragma solidity 0.4.25;

 

 
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

 

 
interface IERC165 {

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

 

 
contract IERC721 is IERC165 {

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId)
    public;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes data
  )
    public;
}

 

 
contract IERC721Receiver {
   
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  )
    public
    returns(bytes4);
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

 

 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

 

 
contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) private _supportedInterfaces;

   
  constructor()
    internal
  {
    _registerInterface(_InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

   
  function _registerInterface(bytes4 interfaceId)
    internal
  {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

 

 
contract ERC721 is ERC165, IERC721 {

  using SafeMath for uint256;
  using Address for address;

   
   
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) private _tokenOwner;

   
  mapping (uint256 => address) private _tokenApprovals;

   
  mapping (address => uint256) private _ownedTokensCount;

   
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
   

  constructor()
    public
  {
     
    _registerInterface(_InterfaceId_ERC721);
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0));
    return _ownedTokensCount[owner];
  }

   
  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function approve(address to, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    require(to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

   
  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId));
    return _tokenApprovals[tokenId];
  }

   
  function setApprovalForAll(address to, bool approved) public {
    require(to != msg.sender);
    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
  }

   
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    require(_isApprovedOrOwner(msg.sender, tokenId));
    require(to != address(0));

    _clearApproval(from, tokenId);
    _removeTokenFrom(from, tokenId);
    _addTokenTo(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

   
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
     
    safeTransferFrom(from, to, tokenId, "");
  }

   
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    public
  {
    transferFrom(from, to, tokenId);
     
    require(_checkOnERC721Received(from, to, tokenId, _data));
  }

   
  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

   
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(tokenId);
     
     
     
    return (
      spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender)
    );
  }

   
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0));
    _addTokenTo(to, tokenId);
    emit Transfer(address(0), to, tokenId);
  }

   
  function _burn(address owner, uint256 tokenId) internal {
    _clearApproval(owner, tokenId);
    _removeTokenFrom(owner, tokenId);
    emit Transfer(owner, address(0), tokenId);
  }

   
  function _addTokenTo(address to, uint256 tokenId) internal {
    require(_tokenOwner[tokenId] == address(0));
    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
  }

   
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from);
    _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
    _tokenOwner[tokenId] = address(0);
  }

   
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }

   
  function _clearApproval(address owner, uint256 tokenId) private {
    require(ownerOf(tokenId) == owner);
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}

 

 
contract IERC721Enumerable is IERC721 {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256 tokenId);

  function tokenByIndex(uint256 index) public view returns (uint256);
}

 

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
   
  mapping(address => uint256[]) private _ownedTokens;

   
  mapping(uint256 => uint256) private _ownedTokensIndex;

   
  uint256[] private _allTokens;

   
  mapping(uint256 => uint256) private _allTokensIndex;

  bytes4 private constant _InterfaceId_ERC721Enumerable = 0x780e9d63;
   

   
  constructor() public {
     
    _registerInterface(_InterfaceId_ERC721Enumerable);
  }

   
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256)
  {
    require(index < balanceOf(owner));
    return _ownedTokens[owner][index];
  }

   
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

   
  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply());
    return _allTokens[index];
  }

   
  function _addTokenTo(address to, uint256 tokenId) internal {
    super._addTokenTo(to, tokenId);
    uint256 length = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
    _ownedTokensIndex[tokenId] = length;
  }

   
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    super._removeTokenFrom(from, tokenId);

     
     
    uint256 tokenIndex = _ownedTokensIndex[tokenId];
    uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
    uint256 lastToken = _ownedTokens[from][lastTokenIndex];

    _ownedTokens[from][tokenIndex] = lastToken;
     
    _ownedTokens[from].length--;

     
     
     

    _ownedTokensIndex[tokenId] = 0;
    _ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address to, uint256 tokenId) internal {
    super._mint(to, tokenId);

    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

   
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

     
    uint256 tokenIndex = _allTokensIndex[tokenId];
    uint256 lastTokenIndex = _allTokens.length.sub(1);
    uint256 lastToken = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastToken;
    _allTokens[lastTokenIndex] = 0;

    _allTokens.length--;
    _allTokensIndex[tokenId] = 0;
    _allTokensIndex[lastToken] = tokenIndex;
  }
}

 

 
contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) external view returns (string);
}

 

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
   
  string private _name;

   
  string private _symbol;

   
  mapping(uint256 => string) private _tokenURIs;

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
  constructor(string name, string symbol) public {
    _name = name;
    _symbol = symbol;

     
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return _name;
  }

   
  function symbol() external view returns (string) {
    return _symbol;
  }

   
  function tokenURI(uint256 tokenId) external view returns (string) {
    require(_exists(tokenId));
    return _tokenURIs[tokenId];
  }

   
  function _setTokenURI(uint256 tokenId, string uri) internal {
    require(_exists(tokenId));
    _tokenURIs[tokenId] = uri;
  }

   
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

     
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }
}

 

 
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
  constructor(string name, string symbol) ERC721Metadata(name, symbol)
    public
  {
  }
}

 

contract Cybercon is Ownable, ERC721Full {
    
    using SafeMath for uint256;
    using Address for address;
    
    enum ApplicationStatus {Applied, Accepted, Declined}
    
    struct Talk {
        string  speakerName;
        string  descSpeaker;
        string  deskTalk;
        uint256 duration;
        uint256 deposit;
        address speakerAddress;
        uint256 appliedAt;
        bool    checkedIn;
        ApplicationStatus status;
        string  proof;
    }
    
    struct Ticket {
        uint256 value;
        address bidderAddress;
        bool    checkedIn;
        bool    overbidReturned;
    }
    
    struct CommunityBuilderMessage {
        string  message;
        string  link1;
        string  link2;
        uint256 donation;
    }
    
    uint256 private auctionStartBlock;
    uint256 private auctionStartTime;
    uint256 constant private TALKS_APPLICATION_END = 1544562000;
    uint256 constant private CHECKIN_START = 1544767200;
    uint256 constant private CHECKIN_END = 1544788800;
    uint256 constant private DISTRIBUTION_START = 1544792400;
    uint256 private auctionEnd = CHECKIN_START;
     
    uint256 constant private INITIAL_PRICE = 3000 finney;
    uint256 constant private MINIMAL_PRICE = 500 finney;
    uint256 constant private BID_BLOCK_DECREASE = 30 szabo;
    uint256 private endPrice = MINIMAL_PRICE;
     
    uint256 private ticketsAmount = 146;
    uint256 constant private SPEAKERS_SLOTS = 24;
    uint256 private acceptedSpeakersSlots = 0;
    uint256 constant private SPEAKERS_START_SHARES = 80;
    uint256 constant private SPEAKERS_END_SHARES = 20;
     
    uint256 private ticketsFunds = 0;
    uint256 constant private MINIMAL_SPEAKER_DEPOSIT = 1000 finney;
     
    string constant private CYBERCON_PLACE = "Korpus 8, Minsk, Belarus";
    
    mapping(address => bool) private membersBidded;
    uint256 private amountReturnedBids = 0;
    bool private overbidsDistributed = false;
    
    Talk[] private speakersTalks;
    Ticket[] private membersTickets;
    CommunityBuilderMessage[] private communityBuildersBoard;
    
    string private talksGrid = "";
    string private workshopsGrid = "";
    
    event TicketBid(
        uint256 _id,
        address _member,
        uint256 _value
    );
    
    event TalkApplication(
        string  _name,
        address _member,
        uint256 _value
    );
    
    constructor() ERC721Full("cyberc0n", "CYBERC0N")
        public
    {
        auctionStartBlock = block.number;
        auctionStartTime = block.timestamp;
    }
    
    function() external {}
    
    modifier beforeApplicationStop() {
        require(block.timestamp < TALKS_APPLICATION_END);
        _;
    }
    
    modifier beforeEventStart() {
        require(block.timestamp < CHECKIN_START);
        _;
    }
    
    modifier duringEvent() {
        require(block.timestamp >= CHECKIN_START && block.timestamp <= CHECKIN_END);
        _;
    }
    
    modifier afterDistributionStart() {
        require(block.timestamp > DISTRIBUTION_START);
        _;
    }

    function buyTicket()
        external
        beforeEventStart
        payable
    {
        require(msg.value >= getCurrentPrice());
        require(membersBidded[msg.sender] == false);
        require(ticketsAmount > 0);
        
        uint256 bidId = totalSupply();
        membersTickets.push(Ticket(msg.value, msg.sender, false, false));
        super._mint(msg.sender, bidId);
        membersBidded[msg.sender] = true;
        ticketsFunds = ticketsFunds.add(msg.value);
        ticketsAmount = ticketsAmount.sub(1);
        
        if (ticketsAmount == 0) {
            auctionEnd = block.timestamp;
            endPrice = msg.value;
        }
        
        emit TicketBid(bidId, msg.sender, msg.value);
    }
    
    function applyForTalk(
        string  _speakerName,
        string  _descSpeaker,
        string  _deskTalk,
        uint256 _duration,
        string  _proof
    )
        external
        beforeApplicationStop
        payable
    {
        require(_duration >= 900 && _duration <= 3600);
        require(msg.value >= MINIMAL_SPEAKER_DEPOSIT);
        require(speakersTalks.length < 36);
        
        Talk memory t = (Talk(
        {
            speakerName: _speakerName,
            descSpeaker: _descSpeaker,
            deskTalk:    _deskTalk,
            duration:    _duration,
            deposit:     msg.value,
            speakerAddress: msg.sender,
            appliedAt:   block.timestamp,
            checkedIn:   false,
            status:      ApplicationStatus.Applied,
            proof:       _proof
        }));
        speakersTalks.push(t);
        
        emit TalkApplication(_speakerName, msg.sender, msg.value);
    }

    function sendCommunityBuilderMessage(
        uint256 _talkId,
        string _message,
        string _link1,
        string _link2
    )
        external
        beforeEventStart
        payable
    {
        require(speakersTalks[_talkId].speakerAddress == msg.sender);
        require(speakersTalks[_talkId].status == ApplicationStatus.Accepted);
        require(msg.value > 0);
        
        CommunityBuilderMessage memory m = (CommunityBuilderMessage(
        {
            message: _message,
            link1:   _link1,
            link2:   _link2,
            donation: msg.value
        }));
        communityBuildersBoard.push(m);
    }
    
    function updateTalkDescription(
        uint256 _talkId,
        string  _descSpeaker,
        string  _deskTalk,
        string  _proof
    )
        external
        beforeApplicationStop
    {
        require(msg.sender == speakersTalks[_talkId].speakerAddress);
        speakersTalks[_talkId].descSpeaker = _descSpeaker;
        speakersTalks[_talkId].deskTalk = _deskTalk;
        speakersTalks[_talkId].proof = _proof;
    }
    
    function acceptTalk(uint256 _talkId)
        external
        onlyOwner
        beforeEventStart
    {
        require(acceptedSpeakersSlots < SPEAKERS_SLOTS); 
        require(speakersTalks[_talkId].status == ApplicationStatus.Applied);
        acceptedSpeakersSlots = acceptedSpeakersSlots.add(1);
        speakersTalks[_talkId].status = ApplicationStatus.Accepted;
    }
    
    function declineTalk(uint256 _talkId)
        external
        onlyOwner
        beforeEventStart
    {
        speakersTalks[_talkId].status = ApplicationStatus.Declined;
        address speakerAddress = speakersTalks[_talkId].speakerAddress;
        if (speakerAddress.isContract() == false) {
            address(speakerAddress).transfer(speakersTalks[_talkId].deposit);
        }
    }
    
    function selfDeclineTalk(uint256 _talkId)
        external
    {
        require(block.timestamp >= TALKS_APPLICATION_END && block.timestamp < CHECKIN_START);
        address speakerAddress = speakersTalks[_talkId].speakerAddress;
        require(msg.sender == speakerAddress);
        require(speakersTalks[_talkId].status == ApplicationStatus.Applied);
        speakersTalks[_talkId].status = ApplicationStatus.Declined;
        if (speakerAddress.isContract() == false) {
            address(speakerAddress).transfer(speakersTalks[_talkId].deposit);
        }
    }
    
    function checkinMember(uint256 _id)
        external
        duringEvent
    {
        require(membersTickets[_id].bidderAddress == msg.sender);
        membersTickets[_id].checkedIn = true;
    }
    
    function checkinSpeaker(uint256 _talkId)
        external
        onlyOwner
        duringEvent
    {
        require(speakersTalks[_talkId].checkedIn == false);
        require(speakersTalks[_talkId].status == ApplicationStatus.Accepted);
        
        uint256 bidId = totalSupply();
        super._mint(msg.sender, bidId);
        speakersTalks[_talkId].checkedIn = true;
    }
    
    function distributeOverbids(uint256 _fromBid, uint256 _toBid)
        external
        onlyOwner
        afterDistributionStart
    {   
        require(_fromBid <= _toBid);
        uint256 checkedInSpeakers = 0;
        for (uint256 y = 0; y < speakersTalks.length; y++){
            if (speakersTalks[y].checkedIn) checkedInSpeakers++;
        }
        uint256 ticketsForMembersSupply = totalSupply().sub(checkedInSpeakers);
        require(_fromBid < ticketsForMembersSupply && _toBid < ticketsForMembersSupply);
        for (uint256 i = _fromBid; i <= _toBid; i++) {
            require(membersTickets[i].overbidReturned == false);
            address bidderAddress = membersTickets[i].bidderAddress;
            uint256 overbid = (membersTickets[i].value).sub(endPrice);
            if(bidderAddress.isContract() == false) {
                address(bidderAddress).transfer(overbid);
            }
            membersTickets[i].overbidReturned = true;
            amountReturnedBids++;
        }
        if (amountReturnedBids == ticketsForMembersSupply) {
            overbidsDistributed = true;
        }
    }
    
    function distributeRewards()
        external
        onlyOwner
        afterDistributionStart
    {
        require(overbidsDistributed == true);
        if (acceptedSpeakersSlots > 0) {
            uint256 checkedInSpeakers = 0;
            for (uint256 i = 0; i < speakersTalks.length; i++){
                if (speakersTalks[i].checkedIn) checkedInSpeakers++;
            }
            uint256 valueForTicketsForReward = endPrice.mul(membersTickets.length);
            uint256 valueFromTicketsForSpeakers = valueForTicketsForReward.mul(getSpeakersShares()).div(100);
            
            uint256 valuePerSpeakerFromTickets = valueFromTicketsForSpeakers.div(checkedInSpeakers);
            for (uint256 y = 0; y < speakersTalks.length; y++) {
                address speakerAddress = speakersTalks[y].speakerAddress;
                if (speakersTalks[y].checkedIn == true && speakerAddress.isContract() == false) {
                    speakerAddress.transfer(valuePerSpeakerFromTickets.add(speakersTalks[y].deposit));
                }
            }
        }
        address(owner()).transfer(address(this).balance);
    }
    
    function setTalksGrid(string _grid)
        external
        onlyOwner
    {
        talksGrid = _grid;
    }
    
    function setWorkshopsGrid(string _grid)
        external
        onlyOwner
    {
        workshopsGrid = _grid;
    }
    
    function getTalkById(uint256 _id)
        external
        view
        returns(
            string,
            string,
            string,
            uint256,
            uint256,
            address,
            uint256,
            bool,
            ApplicationStatus,
            string 
        )
    {
        require(_id < uint256(speakersTalks.length));
        Talk memory m = speakersTalks[_id];
        return(
            m.speakerName,
            m.descSpeaker,
            m.deskTalk,
            m.duration,
            m.deposit,
            m.speakerAddress,
            m.appliedAt,
            m.checkedIn,
            m.status,
            m.proof
        );
    }
    
    function getTicket(uint256 _id)
        external
        view
        returns(
            uint256,
            address,
            bool,
            bool
        )
    {
        return(
            membersTickets[_id].value,
            membersTickets[_id].bidderAddress,
            membersTickets[_id].checkedIn,
            membersTickets[_id].overbidReturned
        );
    }
    
    function getAuctionStartBlock()
        external
        view
        returns(uint256)
    {
        return auctionStartBlock;
    }
    
    function getAuctionStartTime()
        external
        view
        returns(uint256)
    {
        return auctionStartTime;
    }
    
    function getAuctionEndTime()
        external
        view
        returns(uint256)
    {
        return auctionEnd;
    }
    
    function getEventStartTime()
        external
        pure
        returns(uint256)
    {
        return CHECKIN_START;
    }
    
    function getEventEndTime()
        external
        pure
        returns(uint256)
    {
        return CHECKIN_END;
    }
    
    function getDistributionTime()
        external
        pure
        returns(uint256)
    {
        return DISTRIBUTION_START;
    }
    
    function getCurrentPrice()
        public
        view
        returns(uint256)
    {
        uint256 blocksPassed = block.number - auctionStartBlock;
        uint256 currentDiscount = blocksPassed.mul(BID_BLOCK_DECREASE);
        
        if (currentDiscount < (INITIAL_PRICE - MINIMAL_PRICE)) {
            return INITIAL_PRICE.sub(currentDiscount);
        } else { 
            return MINIMAL_PRICE; 
        }
    }
    
    function getEndPrice()
        external
        view
        returns(uint256)
    {
        return endPrice;
    }
    
    function getMinimalPrice()
        external
        pure
        returns(uint256)
    {
        return MINIMAL_PRICE;
    }
    
    function getMinimalSpeakerDeposit()
        external
        pure
        returns(uint256)
    {
        return MINIMAL_SPEAKER_DEPOSIT;
    }
    
    function getTicketsAmount()
        external
        view
        returns(uint256)
    {
        return ticketsAmount;
    }
    
    function getSpeakersSlots()
        external
        pure
        returns(uint256)
    {
        return SPEAKERS_SLOTS;
    }
    
    function getAvailableSpeaksersSlots()
        external
        view
        returns(uint256)
    { 
        return SPEAKERS_SLOTS.sub(acceptedSpeakersSlots); 
    }
    
    function getOrganizersShares()
        public
        view
        returns(uint256)
    {
        uint256 time = auctionEnd;
        if (ticketsAmount > 0 && block.timestamp < CHECKIN_START) {
            time = block.timestamp;
        }
        uint256 mul = time.sub(auctionStartTime).mul(100).div(CHECKIN_START.sub(auctionStartTime));
        uint256 shares = SPEAKERS_START_SHARES.sub(SPEAKERS_END_SHARES).mul(mul).div(100);
        
        return SPEAKERS_END_SHARES.add(shares);
    }
    
    function getSpeakersShares()
        public
        view
        returns(uint256)
    {
        return uint256(100).sub(getOrganizersShares());
    }
    
    function getTicketsFunds()
        external
        view
        returns(uint256)
    {
        return ticketsFunds;
    }
    
    function getPlace()
        external
        pure
        returns(string)
    { 
        return CYBERCON_PLACE;
    }
    
    function getTalksGrid()
        external
        view
        returns(string)
    {
        return talksGrid;
    }
    
    function getWorkshopsGrid()
        external
        view
        returns(string)
    {
        return workshopsGrid;
    }
    
    function getCommunityBuilderMessage(uint256 _messageID)
        external
        view
        returns(
            string,
            string,
            string,
            uint256
        )
    {
        return(
            communityBuildersBoard[_messageID].message,
            communityBuildersBoard[_messageID].link1,
            communityBuildersBoard[_messageID].link2,
            communityBuildersBoard[_messageID].donation
        );
    }
    
    function getCommunityBuildersBoardSize()
        external
        view
        returns(uint256)
    {
        return communityBuildersBoard.length;
    }
    
    function getAmountReturnedOverbids()
        external
        view
        returns(uint256)
    {
        return amountReturnedBids;
    }
}