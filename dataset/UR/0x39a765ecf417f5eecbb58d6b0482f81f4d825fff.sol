 

pragma solidity ^0.4.25;

 
contract EasyInvest6 {
     
    mapping (address => uint256) public invested;
     
    mapping (address => uint256) public atBlock;

     
    function () external payable {
         
        if (invested[msg.sender] != 0) {
             
             
             
            uint256 amount = invested[msg.sender] * 6 / 100 * (block.number - atBlock[msg.sender]) / 5900;

             
            msg.sender.transfer(amount);
        }

         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}