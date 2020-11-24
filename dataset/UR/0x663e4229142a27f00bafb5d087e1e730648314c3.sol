 

pragma solidity ^0.4.11;


contract ERC20 {
    function totalSupply() constant returns (uint supply);
    function balanceOf( address who ) constant returns (uint value);
    function allowance( address owner, address spender ) constant returns (uint _allowance);

    function transfer( address to, uint value) returns (bool ok);
    function transferFrom( address from, address to, uint value) returns (bool ok);
    function approve( address spender, uint value ) returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}
 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
 
contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract GeneScienceInterface {
     
    function isGeneScience() public pure returns (bool);

     
     
     
     
    function mixGenes(uint256[2] genes1, uint256[2] genes2,uint256 g1,uint256 g2, uint256 targetBlock) public returns (uint256[2]);

    function getPureFromGene(uint256[2] gene) public view returns(uint256);

     
    function getSex(uint256[2] gene) public view returns(uint256);

     
    function getWizzType(uint256[2] gene) public view returns(uint256);

    function clearWizzType(uint256[2] _gene) public returns(uint256[2]);
}

 
 
 
contract PandaAccessControl {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    event ContractUpgrade(address newContract);

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

     
    bool public paused = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

     
     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }
}








 
 
 
contract PandaBase is PandaAccessControl {
     

    uint256 public constant GEN0_TOTAL_COUNT = 16200;
    uint256 public gen0CreatedCount;

     
     
     
    event Birth(address owner, uint256 pandaId, uint256 matronId, uint256 sireId, uint256[2] genes);

     
     
    event Transfer(address from, address to, uint256 tokenId);

     

     
     
     
     
    struct Panda {
         
         
        uint256[2] genes;

         
        uint64 birthTime;

         
         
         
        uint64 cooldownEndBlock;

         
         
         
         
         
         
        uint32 matronId;
        uint32 sireId;

         
         
         
         
        uint32 siringWithId;

         
         
         
         
         
        uint16 cooldownIndex;

         
         
         
         
         
        uint16 generation;
    }

     

     
     
     
     
     
     
    uint32[9] public cooldowns = [
        uint32(5 minutes),
        uint32(30 minutes),
        uint32(2 hours),
        uint32(4 hours),    
        uint32(8 hours),
        uint32(24 hours),
        uint32(48 hours),
        uint32(72 hours),
        uint32(7 days)
    ];

     
    uint256 public secondsPerBlock = 15;

     

     
     
     
     
     
    Panda[] pandas;

     
     
    mapping (uint256 => address) public pandaIndexToOwner;

     
     
    mapping (address => uint256) ownershipTokenCount;

     
     
     
    mapping (uint256 => address) public pandaIndexToApproved;

     
     
     
    mapping (uint256 => address) public sireAllowedToAddress;

     
     
     
    SaleClockAuction public saleAuction;

     
     
     
    SiringClockAuction public siringAuction;


     
     
    GeneScienceInterface public geneScience;


    SaleClockAuctionERC20 public saleAuctionERC20;


     
    mapping (uint256 => uint256) public wizzPandaQuota;
    mapping (uint256 => uint256) public wizzPandaCount;

    
     
    function getWizzPandaQuotaOf(uint256 _tp) view external returns(uint256) {
        return wizzPandaQuota[_tp];
    }

    function getWizzPandaCountOf(uint256 _tp) view external returns(uint256) {
        return wizzPandaCount[_tp];
    }

    function setTotalWizzPandaOf(uint256 _tp,uint256 _total) external onlyCLevel {
        require (wizzPandaQuota[_tp]==0);
        require (_total==uint256(uint32(_total)));
        wizzPandaQuota[_tp] = _total;
    }

    function getWizzTypeOf(uint256 _id) view external returns(uint256) {
        Panda memory _p = pandas[_id];
        return geneScience.getWizzType(_p.genes);
    }

     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
        ownershipTokenCount[_to]++;
         
        pandaIndexToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
             
            delete sireAllowedToAddress[_tokenId];
             
            delete pandaIndexToApproved[_tokenId];
        }
         
        Transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
     
     
     
    function _createPanda(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256[2] _genes,
        address _owner
    )
        internal
        returns (uint)
    {
         
         
         
         
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));


         
        uint16 cooldownIndex = 0;
         
        if (pandas.length>0){
            uint16 pureDegree = uint16(geneScience.getPureFromGene(_genes));
            if (pureDegree==0) {
                pureDegree = 1;
            }
            cooldownIndex = 1000/pureDegree;
            if (cooldownIndex%10 < 5){
                cooldownIndex = cooldownIndex/10;
            }else{
                cooldownIndex = cooldownIndex/10 + 1;
            }
            cooldownIndex = cooldownIndex - 1;
            if (cooldownIndex > 8) {
                cooldownIndex = 8;
            }
            uint256 _tp = geneScience.getWizzType(_genes);
            if (_tp>0 && wizzPandaQuota[_tp]<=wizzPandaCount[_tp]) {
                _genes = geneScience.clearWizzType(_genes);
                _tp = 0;
            }
             
            if (_tp == 1){
                cooldownIndex = 5;
            }

             
            if (_tp>0){
                wizzPandaCount[_tp] = wizzPandaCount[_tp] + 1;
            }
             
            if (_generation <= 1 && _tp != 1){
                require(gen0CreatedCount<GEN0_TOTAL_COUNT);
                gen0CreatedCount++;
            }
        }

        Panda memory _panda = Panda({
            genes: _genes,
            birthTime: uint64(now),
            cooldownEndBlock: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            siringWithId: 0,
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation)
        });
        uint256 newKittenId = pandas.push(_panda) - 1;

         
         
        require(newKittenId == uint256(uint32(newKittenId)));

         
        Birth(
            _owner,
            newKittenId,
            uint256(_panda.matronId),
            uint256(_panda.sireId),
            _panda.genes
        );

         
         
        _transfer(0, _owner, newKittenId);
        
        return newKittenId;
    }

     
    function setSecondsPerBlock(uint256 secs) external onlyCLevel {
        require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}
 
 
contract ERC721Metadata {
     
    function getMetadata(uint256 _tokenId, string) public view returns (bytes32[4] buffer, uint256 count) {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}







 
 
 
 
contract PandaOwnership is PandaBase, ERC721 {

     
    string public constant name = "PandaEarth";
    string public constant symbol = "PE";

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('tokensOfOwner(address)')) ^
        bytes4(keccak256('tokenMetadata(uint256,string)'));

     
     
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
         
         

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

     
     
     

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return pandaIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return pandaIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        pandaIndexToApproved[_tokenId] = _approved;
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
         
         
        require(_to != address(saleAuction));
        require(_to != address(siringAuction));

         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_owns(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint) {
        return pandas.length - 1;
    }

     
     
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = pandaIndexToOwner[_tokenId];

        require(owner != address(0));
    }

     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCats = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 catId;

            for (catId = 1; catId <= totalCats; catId++) {
                if (pandaIndexToOwner[catId] == _owner) {
                    result[resultIndex] = catId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

     
     
     
    function _memcpy(uint _dest, uint _src, uint _len) private view {
         
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

         
        uint256 mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

     
     
     
    function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private view returns (string) {
        var outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            outputPtr := add(outputString, 32)
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }

}




 
 
 
contract PandaBreeding is PandaOwnership {

    uint256 public constant GENSIS_TOTAL_COUNT = 100;

     
     
    event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 cooldownEndBlock);
     
    event Abortion(address owner, uint256 matronId, uint256 sireId);

     
     
     
    uint256 public autoBirthFee = 2 finney;

     
    uint256 public pregnantPandas;

    mapping(uint256 => address) childOwner;


     
     
    function setGeneScienceAddress(address _address) external onlyCEO {
        GeneScienceInterface candidateContract = GeneScienceInterface(_address);

         
        require(candidateContract.isGeneScience());

         
        geneScience = candidateContract;
    }

     
     
     
    function _isReadyToBreed(Panda _kit) internal view returns(bool) {
         
         
         
        return (_kit.siringWithId == 0) && (_kit.cooldownEndBlock <= uint64(block.number));
    }

     
     
     
    function _isSiringPermitted(uint256 _sireId, uint256 _matronId) internal view returns(bool) {
        address matronOwner = pandaIndexToOwner[_matronId];
        address sireOwner = pandaIndexToOwner[_sireId];

         
         
        return (matronOwner == sireOwner || sireAllowedToAddress[_sireId] == matronOwner);
    }

     
     
     
    function _triggerCooldown(Panda storage _kitten) internal {
         
        _kitten.cooldownEndBlock = uint64((cooldowns[_kitten.cooldownIndex] / secondsPerBlock) + block.number);


         
         
         
        if (_kitten.cooldownIndex < 8 && geneScience.getWizzType(_kitten.genes) != 1) {
            _kitten.cooldownIndex += 1;
        }
    }

     
     
     
     
    function approveSiring(address _addr, uint256 _sireId)
    external
    whenNotPaused {
        require(_owns(msg.sender, _sireId));
        sireAllowedToAddress[_sireId] = _addr;
    }

     
     
     
    function setAutoBirthFee(uint256 val) external onlyCOO {
        autoBirthFee = val;
    }

     
     
    function _isReadyToGiveBirth(Panda _matron) private view returns(bool) {
        return (_matron.siringWithId != 0) && (_matron.cooldownEndBlock <= uint64(block.number));
    }

     
     
     
    function isReadyToBreed(uint256 _pandaId)
    public
    view
    returns(bool) {
        require(_pandaId > 0);
        Panda storage kit = pandas[_pandaId];
        return _isReadyToBreed(kit);
    }

     
     
    function isPregnant(uint256 _pandaId)
    public
    view
    returns(bool) {
        require(_pandaId > 0);
         
        return pandas[_pandaId].siringWithId != 0;
    }

     
     
     
     
     
     
    function _isValidMatingPair(
        Panda storage _matron,
        uint256 _matronId,
        Panda storage _sire,
        uint256 _sireId
    )
    private
    view
    returns(bool) {
         
        if (_matronId == _sireId) {
            return false;
        }

         
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

         
         
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

         
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

         
        if (geneScience.getSex(_matron.genes) + geneScience.getSex(_sire.genes) != 1) {
            return false;
        }

         
        return true;
    }

     
     
    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
    internal
    view
    returns(bool) {
        Panda storage matron = pandas[_matronId];
        Panda storage sire = pandas[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

     
     
     
     
     
     
    function canBreedWith(uint256 _matronId, uint256 _sireId)
    external
    view
    returns(bool) {
        require(_matronId > 0);
        require(_sireId > 0);
        Panda storage matron = pandas[_matronId];
        Panda storage sire = pandas[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId) &&
            _isSiringPermitted(_sireId, _matronId);
    }

    function _exchangeMatronSireId(uint256 _matronId, uint256 _sireId) internal returns(uint256, uint256) {
        if (geneScience.getSex(pandas[_matronId].genes) == 1) {
            return (_sireId, _matronId);
        } else {
            return (_matronId, _sireId);
        }
    }

     
     
    function _breedWith(uint256 _matronId, uint256 _sireId, address _owner) internal {
         
        (_matronId, _sireId) = _exchangeMatronSireId(_matronId, _sireId);
         
        Panda storage sire = pandas[_sireId];
        Panda storage matron = pandas[_matronId];

         
        matron.siringWithId = uint32(_sireId);

         
        _triggerCooldown(sire);
        _triggerCooldown(matron);

         
         
        delete sireAllowedToAddress[_matronId];
        delete sireAllowedToAddress[_sireId];

         
        pregnantPandas++;

        childOwner[_matronId] = _owner;

         
        Pregnant(pandaIndexToOwner[_matronId], _matronId, _sireId, matron.cooldownEndBlock);
    }

     
     
     
     
     
    function breedWithAuto(uint256 _matronId, uint256 _sireId)
    external
    payable
    whenNotPaused {
         
        require(msg.value >= autoBirthFee);

         
        require(_owns(msg.sender, _matronId));

         
         
         
         
         
         
         
         
         
         

         
         
         
        require(_isSiringPermitted(_sireId, _matronId));

         
        Panda storage matron = pandas[_matronId];

         
        require(_isReadyToBreed(matron));

         
        Panda storage sire = pandas[_sireId];

         
        require(_isReadyToBreed(sire));

         
        require(_isValidMatingPair(
            matron,
            _matronId,
            sire,
            _sireId
        ));

         
        _breedWith(_matronId, _sireId, msg.sender);
    }

     
     
     
     
     
     
     
     
    function giveBirth(uint256 _matronId, uint256[2] _childGenes, uint256[2] _factors)
    external
    whenNotPaused
    onlyCLevel
    returns(uint256) {
         
        Panda storage matron = pandas[_matronId];

         
        require(matron.birthTime != 0);

         
        require(_isReadyToGiveBirth(matron));

         
        uint256 sireId = matron.siringWithId;
        Panda storage sire = pandas[sireId];

         
        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

         
         
        uint256[2] memory childGenes = _childGenes;

        uint256 kittenId = 0;

         
        uint256 probability = (geneScience.getPureFromGene(matron.genes) + geneScience.getPureFromGene(sire.genes)) / 2 + _factors[0];
        if (probability >= (parentGen + 1) * _factors[1]) {
            probability = probability - (parentGen + 1) * _factors[1];
        } else {
            probability = 0;
        }
        if (parentGen == 0 && gen0CreatedCount == GEN0_TOTAL_COUNT) {
            probability = 0;
        }
        if (uint256(keccak256(block.blockhash(block.number - 2), now)) % 100 < probability) {
             
            address owner = childOwner[_matronId];
            kittenId = _createPanda(_matronId, matron.siringWithId, parentGen + 1, childGenes, owner);
        } else {
            Abortion(pandaIndexToOwner[_matronId], _matronId, sireId);
        }
         
         
         
         

         
         
        delete matron.siringWithId;

         
        pregnantPandas--;

         
        msg.sender.send(autoBirthFee);

        delete childOwner[_matronId];

         
        return kittenId;
    }
}





 
 
 
contract ClockAuctionBase {

     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
         
        uint64 isGen0;
    }

     
    ERC721 public nonFungibleContract;

     
     
    uint256 public ownerCut;

     
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
     
     
     
    function _escrow(address _owner, uint256 _tokenId) internal {
         
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

     
     
     
     
    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    } 

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

     
     
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
         
        Auction storage auction = tokenIdToAuction[_tokenId];

         
         
         
         
        require(_isOnAuction(auction));

         
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_tokenId);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
        }

         
         
         
         
        uint256 bidExcess = _bidAmount - price;

         
         
         
        msg.sender.transfer(bidExcess);

         
        AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }



     
     
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

     
     
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

     
     
     
     
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

         
         
         
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

     
     
     
     
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
         
         
         
         
         
        if (_secondsPassed >= _duration) {
             
             
            return _endingPrice;
        } else {
             
             
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

             
             
             
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

             
             
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

     
     
    function _computeCut(uint256 _price) internal view returns (uint256) {
         
         
         
         
         
        return _price * ownerCut / 10000;
    }

}




 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


 
 
contract ClockAuction is Pausable, ClockAuctionBase {

     
     
     
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

     
     
     
     
     
     
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

     
     
     
     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
         
        bool res = nftAddress.send(this.balance);
    }

     
     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
        whenNotPaused
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now),
            0
        );
        _addAuction(_tokenId, auction);
    }

     
     
     
    function bid(uint256 _tokenId)
        external
        payable
        whenNotPaused
    {
         
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

     
     
     
     
     
    function cancelAuction(uint256 _tokenId)
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

     
     
     
     
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

     
     
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

     
     
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}




 
 
contract SiringClockAuction is ClockAuction {

     
     
    bool public isSiringClockAuction = true;

     
    function SiringClockAuction(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

     
     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now),
            0
        );
        _addAuction(_tokenId, auction);
    }

     
     
     
     
    function bid(uint256 _tokenId)
        external
        payable
    {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
         
        _bid(_tokenId, msg.value);
         
         
        _transfer(seller, _tokenId);
    }

}




 
 
contract SaleClockAuction is ClockAuction {

     
     
    bool public isSaleClockAuction = true;

     
    uint256 public gen0SaleCount;
    uint256[5] public lastGen0SalePrices;
    uint256 public constant SurpriseValue = 10 finney;

    uint256[] CommonPanda;
    uint256[] RarePanda;
    uint256   CommonPandaIndex;
    uint256   RarePandaIndex;

     
    function SaleClockAuction(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {
            CommonPandaIndex = 1;
            RarePandaIndex   = 1;
    }

     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now),
            0
        );
        _addAuction(_tokenId, auction);
    }

    function createGen0Auction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now),
            1
        );
        _addAuction(_tokenId, auction);
    }    

     
     
    function bid(uint256 _tokenId)
        external
        payable
    {
         
        uint64 isGen0 = tokenIdToAuction[_tokenId].isGen0;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

         
        if (isGen0 == 1) {
             
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    function createPanda(uint256 _tokenId,uint256 _type)
        external
    {
        require(msg.sender == address(nonFungibleContract));
        if (_type == 0) {
            CommonPanda.push(_tokenId);
        }else {
            RarePanda.push(_tokenId);
        }
    }

    function surprisePanda()
        external
        payable
    {
        bytes32 bHash = keccak256(block.blockhash(block.number),block.blockhash(block.number-1));
        uint256 PandaIndex;
        if (bHash[25] > 0xC8) {
            require(uint256(RarePanda.length) >= RarePandaIndex);
            PandaIndex = RarePandaIndex;
            RarePandaIndex ++;

        } else{
            require(uint256(CommonPanda.length) >= CommonPandaIndex);
            PandaIndex = CommonPandaIndex;
            CommonPandaIndex ++;
        }
        _transfer(msg.sender,PandaIndex);
    }

    function packageCount() external view returns(uint256 common,uint256 surprise) {
        common   = CommonPanda.length + 1 - CommonPandaIndex;
        surprise = RarePanda.length + 1 - RarePandaIndex;
    }

    function averageGen0SalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 5;
    }

}



 
 
contract SaleClockAuctionERC20 is ClockAuction {


    event AuctionERC20Created(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration, address erc20Contract);

     
     
    bool public isSaleClockAuctionERC20 = true;

    mapping (uint256 => address) public tokenIdToErc20Address;

    mapping (address => uint256) public erc20ContractsSwitcher;

    mapping (address => uint256) public balances;
    
     
    function SaleClockAuctionERC20(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

    function erc20ContractSwitch(address _erc20address, uint256 _onoff) external{
        require (msg.sender == address(nonFungibleContract));

        require (_erc20address != address(0));

        erc20ContractsSwitcher[_erc20address] = _onoff;
    }
     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        address _erc20Address,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));

        require (erc20ContractsSwitcher[_erc20Address] > 0);
        
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now),
            0
        );
        _addAuctionERC20(_tokenId, auction, _erc20Address);
        tokenIdToErc20Address[_tokenId] = _erc20Address;
    }

     
     
     
     
    function _addAuctionERC20(uint256 _tokenId, Auction _auction, address _erc20address) internal {
         
         
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionERC20Created(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration),
            _erc20address
        );
    }   

    function bid(uint256 _tokenId)
        external
        payable{
             
    }

     
     
    function bidERC20(uint256 _tokenId,uint256 _amount)
        external
    {
         
        address seller = tokenIdToAuction[_tokenId].seller;
        address _erc20address = tokenIdToErc20Address[_tokenId];
        require (_erc20address != address(0));
        uint256 price = _bidERC20(_erc20address,msg.sender,_tokenId, _amount);
        _transfer(msg.sender, _tokenId);
        delete tokenIdToErc20Address[_tokenId];
    }

    function cancelAuction(uint256 _tokenId)
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
        delete tokenIdToErc20Address[_tokenId];
    }

    function withdrawERC20Balance(address _erc20Address, address _to) external returns(bool res)  {
        require (balances[_erc20Address] > 0);
        require(msg.sender == address(nonFungibleContract));
        ERC20(_erc20Address).transfer(_to, balances[_erc20Address]);
    }
    
     
     
    function _bidERC20(address _erc20Address,address _buyerAddress, uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
         
        Auction storage auction = tokenIdToAuction[_tokenId];

         
         
         
         
        require(_isOnAuction(auction));


        require (_erc20Address != address(0) && _erc20Address == tokenIdToErc20Address[_tokenId]);
        

         
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_tokenId);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

             
             
            require(ERC20(_erc20Address).transferFrom(_buyerAddress,seller,sellerProceeds));
            if (auctioneerCut > 0){
                require(ERC20(_erc20Address).transferFrom(_buyerAddress,address(this),auctioneerCut));
                balances[_erc20Address] += auctioneerCut;
            }
        }

         
        AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }
}


 
 
 
contract PandaAuction is PandaBreeding {

     
     
     
     

     
     
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

         
        require(candidateContract.isSaleClockAuction());

         
        saleAuction = candidateContract;
    }

    function setSaleAuctionERC20Address(address _address) external onlyCEO {
        SaleClockAuctionERC20 candidateContract = SaleClockAuctionERC20(_address);

         
        require(candidateContract.isSaleClockAuctionERC20());

         
        saleAuctionERC20 = candidateContract;
    }

     
     
    function setSiringAuctionAddress(address _address) external onlyCEO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);

         
        require(candidateContract.isSiringClockAuction());

         
        siringAuction = candidateContract;
    }

     
     
    function createSaleAuction(
        uint256 _pandaId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _pandaId));
         
         
         
        require(!isPregnant(_pandaId));
        _approve(_pandaId, saleAuction);
         
         
        saleAuction.createAuction(
            _pandaId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

     
     
    function createSaleAuctionERC20(
        uint256 _pandaId,
        address _erc20address,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _pandaId));
         
         
         
        require(!isPregnant(_pandaId));
        _approve(_pandaId, saleAuctionERC20);
         
         
        saleAuctionERC20.createAuction(
            _pandaId,
            _erc20address,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    function switchSaleAuctionERC20For(address _erc20address, uint256 _onoff) external onlyCOO{
        saleAuctionERC20.erc20ContractSwitch(_erc20address,_onoff);
    }


     
     
     
    function createSiringAuction(
        uint256 _pandaId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _pandaId));
        require(isReadyToBreed(_pandaId));
        _approve(_pandaId, siringAuction);
         
         
        siringAuction.createAuction(
            _pandaId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

     
     
     
     
    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId
    )
        external
        payable
        whenNotPaused
    {
         
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));

         
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);

         
        siringAuction.bid.value(msg.value - autoBirthFee)(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId), msg.sender);
    }

     
     
     
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
    }


    function withdrawERC20Balance(address _erc20Address, address _to) external onlyCLevel {
        require(saleAuctionERC20 != address(0));
        saleAuctionERC20.withdrawERC20Balance(_erc20Address,_to);
    }    
}





 
contract PandaMinting is PandaAuction {

     
     
    uint256 public constant GEN0_CREATION_LIMIT = 45000;


     
    uint256 public constant GEN0_STARTING_PRICE = 100 finney;
    uint256 public constant GEN0_AUCTION_DURATION = 1 days;
    uint256 public constant OPEN_PACKAGE_PRICE = 10 finney;


     
     


     
     
     
    function createWizzPanda(uint256[2] _genes, uint256 _generation, address _owner) external onlyCOO {
        address pandaOwner = _owner;
        if (pandaOwner == address(0)) {
            pandaOwner = cooAddress;
        }

        _createPanda(0, 0, _generation, _genes, pandaOwner);
    }

     
     
     
    function createPanda(uint256[2] _genes,uint256 _generation,uint256 _type)
        external
        payable
        onlyCOO
        whenNotPaused
    {
        require(msg.value >= OPEN_PACKAGE_PRICE);
        uint256 kittenId = _createPanda(0, 0, _generation, _genes, saleAuction);
        saleAuction.createPanda(kittenId,_type);
    }

     
     
     
     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

    function createGen0Auction(uint256 _pandaId) external onlyCOO {
        require(_owns(msg.sender, _pandaId));
         

        _approve(_pandaId, saleAuction);

        saleAuction.createGen0Auction(
            _pandaId,
            _computeNextGen0Price(),
            0,
            GEN0_AUCTION_DURATION,
            msg.sender
        );
    }

     
     
    function _computeNextGen0Price() internal view returns(uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

         
        require(avePrice == uint256(uint128(avePrice)));

        uint256 nextPrice = avePrice + (avePrice / 2);

         
        if (nextPrice < GEN0_STARTING_PRICE) {
            nextPrice = GEN0_STARTING_PRICE;
        }

        return nextPrice;
    }
}



 
 
 
contract PandaCore is PandaMinting {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    address public newContractAddress;


     
    function PandaCore() public {
         
        paused = true;

         
        ceoAddress = msg.sender;

         
        cooAddress = msg.sender;

         
         

         

         
    }

     
    function init() external onlyCEO whenPaused {
         
        require(pandas.length == 0);
         
        uint256[2] memory _genes = [uint256(-1),uint256(-1)];

        wizzPandaQuota[1] = 100;
       _createPanda(0, 0, 0, _genes, address(0));
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
         
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }
    

     
     
     
    function() external payable {
        require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(siringAuction)
        );
    }

     
     
    function getPanda(uint256 _id)
        external
        view
        returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256[2] genes
    ) {
        Panda storage kit = pandas[_id];

         
        isGestating = (kit.siringWithId != 0);
        isReady = (kit.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(kit.cooldownIndex);
        nextActionAt = uint256(kit.cooldownEndBlock);
        siringWithId = uint256(kit.siringWithId);
        birthTime = uint256(kit.birthTime);
        matronId = uint256(kit.matronId);
        sireId = uint256(kit.sireId);
        generation = uint256(kit.generation);
        genes = kit.genes;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(siringAuction != address(0));
        require(geneScience != address(0));
        require(newContractAddress == address(0));

         
        super.unpause();
    }

     
    function withdrawBalance() external onlyCFO {
        uint256 balance = this.balance;
         
        uint256 subtractFees = (pregnantPandas + 1) * autoBirthFee;

        if (balance > subtractFees) {
            cfoAddress.send(balance - subtractFees);
        }
    }
}