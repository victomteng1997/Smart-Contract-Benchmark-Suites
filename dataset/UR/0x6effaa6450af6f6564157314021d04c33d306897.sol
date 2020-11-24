 

pragma solidity ^0.4.24;

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

contract Erc20 {
    function balanceOf(address _owner) view public returns(uint256);
    function transfer(address _to, uint256 _value) public returns(bool);
    function approve(address _spender, uint256 _value) public returns(bool);
}

contract Chai is Erc20 {
    function join(address dst, uint wad) external;
}

contract Exchange {
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) public payable returns (uint256);
}

contract chaiGateway is Ownable {
    Exchange DaiEx = Exchange(0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667);

    Erc20 dai = Erc20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    Chai chai = Chai(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);

    constructor() public {
        dai.approve(address(chai), uint256(-1));
    }

    function () public payable {
        etherTochai(msg.sender);
    }

    function etherTochai(address to) public payable returns(uint256 outAmount){
        uint256 amount = DaiEx.ethToTokenSwapInput.value(msg.value * 993 / 1000)(1, now);
        uint256 before = chai.balanceOf(to);
        chai.join(to, amount);
        outAmount = chai.balanceOf(to) - before;
    }

    function makeprofit() public {
        owner.transfer(address(this).balance);
    }

}