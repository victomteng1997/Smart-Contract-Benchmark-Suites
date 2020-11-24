 

pragma solidity ^0.4.17;

library SafeMathMod {  

    function mul(uint256 a, uint256 b) constant internal returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) constant internal returns(uint256) {
        assert(b != 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256 c) {
        require((c = a - b) < a);
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        require((c = a + b) > a);
    }
}

contract Usdcoins {  
    using SafeMathMod
    for uint256;

     

    address owner;



    string constant public name = "USDC";

    string constant public symbol = "USDC";

    uint256 constant public decimals = 18;

    uint256 constant public totalSupply = 100000000e18;

    uint256 constant private MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event TransferFrom(address indexed _spender, address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function() payable {
        revert();
    }

    function Usdcoins() public {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }



    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }




     


    function transfer(address _to, uint256 _value) public returns(bool success) {
         
        require(_to != address(0));
         


         
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
         
        require(_to != address(0));
         


        uint256 allowance = allowed[_from][msg.sender];
         
        require(_value <= allowance || _from == msg.sender);

         
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);

         
         
        if (allowed[_from][msg.sender] != MAX_UINT256 && _from != msg.sender) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        Transfer(_from, _to, _value);
        return true;
    }

     
    function multiPartyTransfer(address[] _toAddresses, uint256[] _amounts) public {
         
        require(_toAddresses.length <= 255);
         
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            transfer(_toAddresses[i], _amounts[i]);
        }
    }

     
    function multiPartyTransferFrom(address _from, address[] _toAddresses, uint256[] _amounts) public {
         
        require(_toAddresses.length <= 255);
         
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            transferFrom(_from, _toAddresses[i], _amounts[i]);
        }
    }

     
    function approve(address _spender, uint256 _value) public returns(bool success) {
         
        require(_spender != address(0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        remaining = allowed[_owner][_spender];
    }

    function isNotContract(address _addr) private view returns(bool) {
        uint length;
        assembly {
             
            length: = extcodesize(_addr)
        }
        return (length == 0);
    }

}

contract icocontract {  
    using SafeMathMod
    for uint256;

    uint public raisedAmount = 0;
    uint256 public RATE = 400;
    bool public icostart = true;
    address owner;

    Usdcoins public token;

    function icocontract() public {

        owner = msg.sender;


    }

    modifier whenSaleIsActive() {
         
        require(icostart == true);

        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setToken(Usdcoins _token) onlyOwner {

        token = _token;

    }

    function setraisedAmount(uint raised) onlyOwner {

        raisedAmount = raised;

    }

     function setRate(uint256 rate) onlyOwner {

        RATE = rate;

    }

    function setIcostart(bool newicostart) onlyOwner {

        icostart = newicostart;
    }

    function() external payable {
        buyTokens();
    }

    function buyTokens() payable whenSaleIsActive {

         
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(RATE);


         
        raisedAmount = raisedAmount.add(msg.value);

        token.transferFrom(owner, msg.sender, tokens);


         
        owner.transfer(msg.value);
    }


}