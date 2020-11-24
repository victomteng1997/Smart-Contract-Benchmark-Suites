 

pragma solidity 0.4.21;


library SafeMath {
    function mul(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) pure internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) pure internal returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) pure internal returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) pure internal returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) pure internal returns (uint256) {
        return a < b ? a : b;
    }

}

contract ReentrancyGuard {

     
    bool private rentrancy_lock = false;

     
    modifier nonReentrant() {
        require(!rentrancy_lock);
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
    }

}

 

contract MultiSig is ReentrancyGuard{

    using SafeMath for uint256;

     
    struct Transaction{
        address[2] signer;
        uint confirmations;
        uint256 eth;
    }

     
    Transaction private  pending;

     
    uint256 constant public required = 2;

    mapping(address => bool) private administrators;

     
    event Deposit(address _from, uint256 value);

     
    event Transfer(address indexed fristSigner, address indexed secondSigner, address to,uint256 eth,bool success);

     
    event TransferConfirmed(address signer,uint256 amount,uint256 remainingConfirmations);

     
    event UpdateConfirmed(address indexed signer,address indexed newAddress,uint256 remainingConfirmations);


     
    event Violated(string action, address sender);

     
    event KeyReplaced(address oldKey,address newKey);

    event EventTransferWasReset();
    event EventUpdateWasReset();


    function MultiSig() public {

        administrators[0xA45fb4e5A96D267c2BDc5efDD2E93a92b9516232] = true;
        administrators[0x877994c4192184F18E24083Be0aA51BAA325FD9c] = true;
        administrators[0x5Aa9E0727b57cF9aC354626A3Ea137317a30E636] = true;
        administrators[0x8ee5De18c0b70Ccb7844768BAe07db6e208c7082] = true;
        administrators[0x81e9b014d9cd8c5b76bb712cf03eae9a2669e765] = true;
        administrators[0xed4c73ad76d90715d648797acd29a8529ed511a0] = true;

    }

     
    function transfer(address recipient, uint256 amount) external onlyAdmin nonReentrant {

         
        require( recipient != 0x00 );
        require( amount > 0 );
        require( address(this).balance >= amount );

        uint remaining;

         
        if(pending.confirmations == 0){

            pending.signer[pending.confirmations] = msg.sender;
            pending.eth = amount;
            pending.confirmations = pending.confirmations.add(1);
            remaining = required.sub(pending.confirmations);
            emit TransferConfirmed(msg.sender,amount,remaining);
            return;

        }

         
        if(pending.eth != amount){
            transferViolated("Incorrect amount of wei passed");
            return;
        }

         
        if(msg.sender == pending.signer[0]){
            transferViolated("Signer is spamming");
            return;
        }

        pending.signer[pending.confirmations] = msg.sender;
        pending.confirmations = pending.confirmations.add(1);
        remaining = required.sub(pending.confirmations);

         
        if(remaining == 0){
            if(msg.sender == pending.signer[0]){
                transferViolated("One of signers is spamming");
                return;
            }
        }

        emit TransferConfirmed(msg.sender,amount,remaining);

         
        if (pending.confirmations == 2){
            if(recipient.send(amount)){

                emit Transfer(pending.signer[0],pending.signer[1], recipient,amount,true);

            } else {

                emit Transfer(pending.signer[0],pending.signer[1], recipient,amount,false);

            }
            ResetTransferState();
        }
    }

    function transferViolated(string error) private {
        emit Violated(error, msg.sender);
        ResetTransferState();
    }

    function ResetTransferState() internal {
        delete pending;
        emit EventTransferWasReset();
    }


     
    function abortTransaction() external onlyAdmin{
        ResetTransferState();
    }

     
    function() payable public {
         
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

     
    function isAdministrator(address _addr) public constant returns (bool) {
        return administrators[_addr];
    }

     
    struct KeyUpdate{
        address[2] signer;
        uint confirmations;
        address oldAddress;
        address newAddress;
    }

    KeyUpdate private updating;

     
    function updateAdministratorKey(address _oldAddress, address _newAddress) external onlyAdmin {

         
        require(isAdministrator(_oldAddress));
        require( _newAddress != 0x00 );
        require(!isAdministrator(_newAddress));
        require( msg.sender != _oldAddress );

         
        uint256 remaining;

         
         
        if( updating.confirmations == 0){

            updating.signer[updating.confirmations] = msg.sender;
            updating.oldAddress = _oldAddress;
            updating.newAddress = _newAddress;
            updating.confirmations = updating.confirmations.add(1);
            remaining = required.sub(updating.confirmations);
            emit UpdateConfirmed(msg.sender,_newAddress,remaining);
            return;

        }

         
        if(updating.oldAddress != _oldAddress){
            emit Violated("Old addresses do not match",msg.sender);
            ResetUpdateState();
            return;
        }

        if(updating.newAddress != _newAddress){
            emit Violated("New addresses do not match",msg.sender);
            ResetUpdateState();
            return;
        }

         
        if(msg.sender == updating.signer[0]){
            emit Violated("Signer is spamming",msg.sender);
            ResetUpdateState();
            return;
        }

        updating.signer[updating.confirmations] = msg.sender;
        updating.confirmations = updating.confirmations.add(1);
        remaining = required.sub(updating.confirmations);

        if( remaining == 0){
            if(msg.sender == updating.signer[0]){
                emit Violated("One of signers is spamming",msg.sender);
                ResetUpdateState();
                return;
            }
        }

        emit UpdateConfirmed(msg.sender,_newAddress,remaining);

         
        if( updating.confirmations == 2 ){
            emit KeyReplaced(_oldAddress, _newAddress);
            ResetUpdateState();
            delete administrators[_oldAddress];
            administrators[_newAddress] = true;
            return;
        }
    }

    function ResetUpdateState() internal
    {
        delete updating;
        emit EventUpdateWasReset();
    }

     
    function abortUpdate() external onlyAdmin{
        ResetUpdateState();
    }

     
    modifier onlyAdmin(){
        if( !administrators[msg.sender] ){
            revert();
        }
        _;
    }
}