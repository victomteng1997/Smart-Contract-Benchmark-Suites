 

 
 

pragma solidity ^0.4.20;

 
 
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 
 
contract ERC721 is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 
interface ERC721TokenReceiver {
	function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

contract AccessAdmin {
    bool public isPaused = false;
    address public addrAdmin;  

    event AdminTransferred(address indexed preAdmin, address indexed newAdmin);

    function AccessAdmin() public {
        addrAdmin = msg.sender;
    }  


    modifier onlyAdmin() {
        require(msg.sender == addrAdmin);
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused);
        _;
    }

    modifier whenPaused {
        require(isPaused);
        _;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0));
        AdminTransferred(addrAdmin, _newAdmin);
        addrAdmin = _newAdmin;
    }

    function doPause() external onlyAdmin whenNotPaused {
        isPaused = true;
    }

    function doUnpause() external onlyAdmin whenPaused {
        isPaused = false;
    }
}

contract AccessService is AccessAdmin {
    address public addrService;
    address public addrFinance;

    modifier onlyService() {
        require(msg.sender == addrService);
        _;
    }

    modifier onlyFinance() {
        require(msg.sender == addrFinance);
        _;
    }

    function setService(address _newService) external {
        require(msg.sender == addrService || msg.sender == addrAdmin);
        require(_newService != address(0));
        addrService = _newService;
    }

    function setFinance(address _newFinance) external {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        require(_newFinance != address(0));
        addrFinance = _newFinance;
    }

    function withdraw(address _target, uint256 _amount) 
        external 
    {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        require(_amount > 0);
        address receiver = _target == address(0) ? addrFinance : _target;
        uint256 balance = this.balance;
        if (_amount < balance) {
            receiver.transfer(_amount);
        } else {
            receiver.transfer(this.balance);
        }      
    }
}

interface IDataMining {
    function getRecommender(address _target) external view returns(address);
    function subFreeMineral(address _target) external returns(bool);
}

interface IDataEquip {
    function isEquiped(address _target, uint256 _tokenId) external view returns(bool);
    function isEquipedAny2(address _target, uint256 _tokenId1, uint256 _tokenId2) external view returns(bool);
    function isEquipedAny3(address _target, uint256 _tokenId1, uint256 _tokenId2, uint256 _tokenId3) external view returns(bool);
}

contract Random {
    uint256 _seed;

    function _rand() internal returns (uint256) {
        _seed = uint256(keccak256(_seed, block.blockhash(block.number - 1), block.coinbase, block.difficulty));
        return _seed;
    }

    function _randBySeed(uint256 _outSeed) internal view returns (uint256) {
        return uint256(keccak256(_outSeed, block.blockhash(block.number - 1), block.coinbase, block.difficulty));
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
}

contract WarToken is ERC721, AccessAdmin {
     
    struct Fashion {
        uint16 protoId;      
        uint16 quality;      
        uint16 pos;          
        uint16 health;       
        uint16 atkMin;       
        uint16 atkMax;       
        uint16 defence;      
        uint16 crit;         
        uint16 isPercent;    
        uint16 attrExt1;     
        uint16 attrExt2;     
        uint16 attrExt3;     
    }

     
    Fashion[] public fashionArray;

     
    uint256 destroyFashionCount;

     
    mapping (uint256 => address) fashionIdToOwner;

     
    mapping (address => uint256[]) ownerToFashionArray;

     
    mapping (uint256 => uint256) fashionIdToOwnerIndex;

     
    mapping (uint256 => address) fashionIdToApprovals;

     
    mapping (address => mapping (address => bool)) operatorToApprovals;

     
    mapping (address => bool) actionContracts;

    function setActionContract(address _actionAddr, bool _useful) external onlyAdmin {
        actionContracts[_actionAddr] = _useful;
    }

    function getActionContract(address _actionAddr) external view onlyAdmin returns(bool) {
        return actionContracts[_actionAddr];
    }

     
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
    event Transfer(address indexed from, address indexed to, uint256 tokenId);

     
    event CreateFashion(address indexed owner, uint256 tokenId, uint16 protoId, uint16 quality, uint16 pos, uint16 createType);

     
    event ChangeFashion(address indexed owner, uint256 tokenId, uint16 changeType);

     
    event DeleteFashion(address indexed owner, uint256 tokenId, uint16 deleteType);
    
    function WarToken() public {
        addrAdmin = msg.sender;
        fashionArray.length += 1;
    }

     
     
    modifier isValidToken(uint256 _tokenId) {
        require(_tokenId >= 1 && _tokenId <= fashionArray.length);
        require(fashionIdToOwner[_tokenId] != address(0)); 
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address owner = fashionIdToOwner[_tokenId];
        require(msg.sender == owner || msg.sender == fashionIdToApprovals[_tokenId] || operatorToApprovals[owner][msg.sender]);
        _;
    }

     
    function supportsInterface(bytes4 _interfaceId) external view returns(bool) {
         
        return (_interfaceId == 0x01ffc9a7 || _interfaceId == 0x80ac58cd || _interfaceId == 0x8153916a) && (_interfaceId != 0xffffffff);
    }
        
    function name() public pure returns(string) {
        return "WAR Token";
    }

    function symbol() public pure returns(string) {
        return "WAR";
    }

     
     
     
    function balanceOf(address _owner) external view returns(uint256) {
        require(_owner != address(0));
        return ownerToFashionArray[_owner].length;
    }

     
     
     
    function ownerOf(uint256 _tokenId) external view   returns (address owner) {
        return fashionIdToOwner[_tokenId];
    }

     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
        external
        whenNotPaused
    {
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) 
        external
        whenNotPaused
    {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        whenNotPaused
        isValidToken(_tokenId)
        canTransfer(_tokenId)
    {
        address owner = fashionIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner == _from);
        
        _transfer(_from, _to, _tokenId);
    }

     
     
     
    function approve(address _approved, uint256 _tokenId)
        external
        whenNotPaused
    {
        address owner = fashionIdToOwner[_tokenId];
        require(owner != address(0));
        require(msg.sender == owner || operatorToApprovals[owner][msg.sender]);

        fashionIdToApprovals[_tokenId] = _approved;
        Approval(owner, _approved, _tokenId);
    }

     
     
     
    function setApprovalForAll(address _operator, bool _approved) 
        external 
        whenNotPaused
    {
        operatorToApprovals[msg.sender][_operator] = _approved;
        ApprovalForAll(msg.sender, _operator, _approved);
    }

     
     
     
    function getApproved(uint256 _tokenId) external view isValidToken(_tokenId) returns (address) {
        return fashionIdToApprovals[_tokenId];
    }

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorToApprovals[_owner][_operator];
    }

     
     
     
    function totalSupply() external view returns (uint256) {
        return fashionArray.length - destroyFashionCount - 1;
    }

     
     
     
     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if (_from != address(0)) {
            uint256 indexFrom = fashionIdToOwnerIndex[_tokenId];
            uint256[] storage fsArray = ownerToFashionArray[_from];
            require(fsArray[indexFrom] == _tokenId);

             
            if (indexFrom != fsArray.length - 1) {
                uint256 lastTokenId = fsArray[fsArray.length - 1];
                fsArray[indexFrom] = lastTokenId; 
                fashionIdToOwnerIndex[lastTokenId] = indexFrom;
            }
            fsArray.length -= 1; 
            
            if (fashionIdToApprovals[_tokenId] != address(0)) {
                delete fashionIdToApprovals[_tokenId];
            }      
        }

         
        fashionIdToOwner[_tokenId] = _to;
        ownerToFashionArray[_to].push(_tokenId);
        fashionIdToOwnerIndex[_tokenId] = ownerToFashionArray[_to].length - 1;
        
        Transfer(_from != address(0) ? _from : this, _to, _tokenId);
    }

     
    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
        internal
        isValidToken(_tokenId) 
        canTransfer(_tokenId)
    {
        address owner = fashionIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner == _from);
        
        _transfer(_from, _to, _tokenId);

         
        uint256 codeSize;
        assembly { codeSize := extcodesize(_to) }
        if (codeSize == 0) {
            return;
        }
        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, data);
         
        require(retval == 0xf0b9e5ba);
    }

     

     
     
     
     
    function createFashion(address _owner, uint16[9] _attrs, uint16 _createType) 
        external 
        whenNotPaused
        returns(uint256)
    {
        require(actionContracts[msg.sender]);
        require(_owner != address(0));

        uint256 newFashionId = fashionArray.length;
        require(newFashionId < 4294967296);

        fashionArray.length += 1;
        Fashion storage fs = fashionArray[newFashionId];
        fs.protoId = _attrs[0];
        fs.quality = _attrs[1];
        fs.pos = _attrs[2];
        if (_attrs[3] != 0) {
            fs.health = _attrs[3];
        }
        
        if (_attrs[4] != 0) {
            fs.atkMin = _attrs[4];
            fs.atkMax = _attrs[5];
        }
       
        if (_attrs[6] != 0) {
            fs.defence = _attrs[6];
        }
        
        if (_attrs[7] != 0) {
            fs.crit = _attrs[7];
        }

        if (_attrs[8] != 0) {
            fs.isPercent = _attrs[8];
        }
        
        _transfer(0, _owner, newFashionId);
        CreateFashion(_owner, newFashionId, _attrs[0], _attrs[1], _attrs[2], _createType);
        return newFashionId;
    }

     
    function _changeAttrByIndex(Fashion storage _fs, uint16 _index, uint16 _val) internal {
        if (_index == 3) {
            _fs.health = _val;
        } else if(_index == 4) {
            _fs.atkMin = _val;
        } else if(_index == 5) {
            _fs.atkMax = _val;
        } else if(_index == 6) {
            _fs.defence = _val;
        } else if(_index == 7) {
            _fs.crit = _val;
        } else if(_index == 9) {
            _fs.attrExt1 = _val;
        } else if(_index == 10) {
            _fs.attrExt2 = _val;
        } else if(_index == 11) {
            _fs.attrExt3 = _val;
        }
    }

     
     
     
     
     
    function changeFashionAttr(uint256 _tokenId, uint16[4] _idxArray, uint16[4] _params, uint16 _changeType) 
        external 
        whenNotPaused
        isValidToken(_tokenId) 
    {
        require(actionContracts[msg.sender]);

        Fashion storage fs = fashionArray[_tokenId];
        if (_idxArray[0] > 0) {
            _changeAttrByIndex(fs, _idxArray[0], _params[0]);
        }

        if (_idxArray[1] > 0) {
            _changeAttrByIndex(fs, _idxArray[1], _params[1]);
        }

        if (_idxArray[2] > 0) {
            _changeAttrByIndex(fs, _idxArray[2], _params[2]);
        }

        if (_idxArray[3] > 0) {
            _changeAttrByIndex(fs, _idxArray[3], _params[3]);
        }

        ChangeFashion(fashionIdToOwner[_tokenId], _tokenId, _changeType);
    }

     
     
     
    function destroyFashion(uint256 _tokenId, uint16 _deleteType)
        external 
        whenNotPaused
        isValidToken(_tokenId) 
    {
        require(actionContracts[msg.sender]);

        address _from = fashionIdToOwner[_tokenId];
        uint256 indexFrom = fashionIdToOwnerIndex[_tokenId];
        uint256[] storage fsArray = ownerToFashionArray[_from]; 
        require(fsArray[indexFrom] == _tokenId);

        if (indexFrom != fsArray.length - 1) {
            uint256 lastTokenId = fsArray[fsArray.length - 1];
            fsArray[indexFrom] = lastTokenId; 
            fashionIdToOwnerIndex[lastTokenId] = indexFrom;
        }
        fsArray.length -= 1; 

        fashionIdToOwner[_tokenId] = address(0);
        delete fashionIdToOwnerIndex[_tokenId];
        destroyFashionCount += 1;

        Transfer(_from, 0, _tokenId);

        DeleteFashion(_from, _tokenId, _deleteType);
    }

     
    function safeTransferByContract(uint256 _tokenId, address _to) 
        external
        whenNotPaused
    {
        require(actionContracts[msg.sender]);

        require(_tokenId >= 1 && _tokenId <= fashionArray.length);
        address owner = fashionIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner != _to);

        _transfer(owner, _to, _tokenId);
    }

     

     
    function getFashion(uint256 _tokenId) external view isValidToken(_tokenId) returns (uint16[12] datas) {
        Fashion storage fs = fashionArray[_tokenId];
        datas[0] = fs.protoId;
        datas[1] = fs.quality;
        datas[2] = fs.pos;
        datas[3] = fs.health;
        datas[4] = fs.atkMin;
        datas[5] = fs.atkMax;
        datas[6] = fs.defence;
        datas[7] = fs.crit;
        datas[8] = fs.isPercent;
        datas[9] = fs.attrExt1;
        datas[10] = fs.attrExt2;
        datas[11] = fs.attrExt3;
    }

     
    function getOwnFashions(address _owner) external view returns(uint256[] tokens, uint32[] flags) {
        require(_owner != address(0));
        uint256[] storage fsArray = ownerToFashionArray[_owner];
        uint256 length = fsArray.length;
        tokens = new uint256[](length);
        flags = new uint32[](length);
        for (uint256 i = 0; i < length; ++i) {
            tokens[i] = fsArray[i];
            Fashion storage fs = fashionArray[fsArray[i]];
            flags[i] = uint32(uint32(fs.protoId) * 100 + uint32(fs.quality) * 10 + fs.pos);
        }
    }

     
    function getFashionsAttrs(uint256[] _tokens) external view returns(uint16[] attrs) {
        uint256 length = _tokens.length;
        require(length <= 64);
        attrs = new uint16[](length * 11);
        uint256 tokenId;
        uint256 index;
        for (uint256 i = 0; i < length; ++i) {
            tokenId = _tokens[i];
            if (fashionIdToOwner[tokenId] != address(0)) {
                index = i * 11;
                Fashion storage fs = fashionArray[tokenId];
                attrs[index] = fs.health;
                attrs[index + 1] = fs.atkMin;
                attrs[index + 2] = fs.atkMax;
                attrs[index + 3] = fs.defence;
                attrs[index + 4] = fs.crit;
                attrs[index + 5] = fs.isPercent;
                attrs[index + 6] = fs.attrExt1;
                attrs[index + 7] = fs.attrExt2;
                attrs[index + 8] = fs.attrExt3;
            }   
        }
    }
}

contract DataEquip is AccessService, IDataEquip {
    event EquipChanged(address indexed _target);

     
    WarToken public tokenContract;
    mapping (address => uint256) public slotWeapon;
    mapping (address => uint256) public slotHat;
    mapping (address => uint256) public slotCloth;
    mapping (address => uint256) public slotPant;
    mapping (address => uint256) public slotShoes;
    mapping (address => uint256) public slotPet;

    function DataEquip(address _nftAddr) public {
        addrAdmin = msg.sender;
        addrService = msg.sender;
        addrFinance = msg.sender;

        tokenContract = WarToken(_nftAddr);
    }

    function _equipUpOne(address _owner, uint256 _tokenId) private {
        require(tokenContract.ownerOf(_tokenId) == _owner);
        uint16[12] memory attrs = tokenContract.getFashion(_tokenId);
        uint16 pos = attrs[2];
        if (pos == 1) {
            if (slotWeapon[_owner] != _tokenId) {
                slotWeapon[_owner] = _tokenId;
            }
        } else if (pos == 2) {
            if (slotHat[_owner] != _tokenId) {
                slotHat[_owner] = _tokenId;
            }
        } else if (pos == 3) {
            if (slotCloth[_owner] != _tokenId) {
                slotCloth[_owner] = _tokenId;
            }
        } else if (pos == 4) {
            if (slotPant[_owner] != _tokenId) {
                slotPant[_owner] = _tokenId;
            }
        } else if (pos == 5) {
            if (slotShoes[_owner] != _tokenId) {
                slotShoes[_owner] = _tokenId;
            }
        } else if (pos == 9) {
            if (slotPet[_owner] != _tokenId) {
                slotPet[_owner] = _tokenId;
            }
        }
    }

    function _equipDownOne(address _owner, uint16 _index) private {
        if (_index == 0) {
            if (slotWeapon[_owner] != 0) {
                slotWeapon[_owner] = 0;
            }
        } else if (_index == 1) {
            if (slotHat[_owner] != 0) {
                slotHat[_owner] = 0;
            }
        } else if (_index == 2) {
            if (slotCloth[_owner] != 0) {
                slotCloth[_owner] = 0;
            }
        } else if (_index == 3) {
            if (slotPant[_owner] != 0) {
                slotPant[_owner] = 0;
            }
        } else if (_index == 4) {
            if (slotShoes[_owner] != 0) {
                slotShoes[_owner] = 0;
            }
        } else if (_index == 5) {
            if (slotPet[_owner] != 0) {
                slotPet[_owner] = 0;
            }
        }
    }

    function equipUp(uint256[6] _tokens) 
        external 
        whenNotPaused
    {
        for (uint16 i = 0; i < 6; ++i) {
            if (_tokens[i] > 0) {
                _equipUpOne(msg.sender, _tokens[i]);
            } else {
                _equipDownOne(msg.sender, i);       
            }  
        }
        EquipChanged(msg.sender);
    }

    function equipDown(uint256 _tokenId) 
        external
        whenNotPaused 
    {
        
    }    

    function isEquiped(address _target, uint256 _tokenId) external view returns(bool) {
        require(_target != address(0));
        require(_tokenId > 0);

        if (slotWeapon[_target] == _tokenId) {
            return true;
        }

        if (slotHat[_target] == _tokenId) {
            return true;
        }

        if (slotCloth[_target] == _tokenId) {
            return true;
        }

        if (slotPant[_target] == _tokenId) {
            return true;
        }

        if (slotShoes[_target] == _tokenId) {
            return true;
        }

        if (slotPet[_target] == _tokenId) {
            return true;
        }
        return false;
    }

    function isEquipedAny2(address _target, uint256 _tokenId1, uint256 _tokenId2) external view returns(bool) {
        require(_target != address(0));
        require(_tokenId1 > 0);
        require(_tokenId2 > 0);
        
        uint256 equipTokenId = slotWeapon[_target];
        if (equipTokenId == _tokenId1 || equipTokenId == _tokenId2) {
            return true;
        }

        equipTokenId = slotHat[_target];
        if (equipTokenId == _tokenId1 || equipTokenId == _tokenId2) {
            return true;
        }

        equipTokenId = slotCloth[_target];
        if (equipTokenId == _tokenId1 || equipTokenId == _tokenId2) {
            return true;
        }

        equipTokenId = slotPant[_target];
        if (equipTokenId == _tokenId1 || equipTokenId == _tokenId2) {
            return true;
        }

        equipTokenId = slotShoes[_target];
        if (equipTokenId == _tokenId1 || equipTokenId == _tokenId2) {
            return true;
        }

        equipTokenId = slotPet[_target];
        if (equipTokenId == _tokenId1 || equipTokenId == _tokenId2) {
            return true;
        }
        return false;
    }

    function isEquipedAny3(address _target, uint256 _tokenId1, uint256 _tokenId2, uint256 _tokenId3) external view returns(bool) {
        require(_target != address(0));
        require(_tokenId1 > 0);
        require(_tokenId2 > 0);
        require(_tokenId3 > 0);
        
        uint256 equipTokenId = slotWeapon[_target];
        if (equipTokenId == _tokenId1 || equipTokenId == _tokenId2 || equipTokenId == _tokenId3) {
            return true;
        }

        equipTokenId = slotHat[_target];
        if (equipTokenId == _tokenId1 || equipTokenId == _tokenId2 || equipTokenId == _tokenId3) {
            return true;
        }

        equipTokenId = slotCloth[_target];
        if (equipTokenId == _tokenId1 || equipTokenId == _tokenId2 || equipTokenId == _tokenId3) {
            return true;
        }

        equipTokenId = slotPant[_target];
        if (equipTokenId == _tokenId1 || equipTokenId == _tokenId2 || equipTokenId == _tokenId3) {
            return true;
        }

        equipTokenId = slotShoes[_target];
        if (equipTokenId == _tokenId1 || equipTokenId == _tokenId2 || equipTokenId == _tokenId3) {
            return true;
        }

        equipTokenId = slotPet[_target];
        if (equipTokenId == _tokenId1 || equipTokenId == _tokenId2 || equipTokenId == _tokenId3) {
            return true;
        }
        return false;
    }

    function getEquipTokens(address _target) external view returns(uint256[6] tokens) {
        tokens[0] = slotWeapon[_target];
        tokens[1] = slotHat[_target];
        tokens[2] = slotCloth[_target];
        tokens[3] = slotPant[_target];
        tokens[4] = slotShoes[_target];
        tokens[5] = slotPet[_target];
    }
}