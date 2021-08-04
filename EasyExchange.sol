pragma solidity ^0.8.0;
import "contracts/EasyToken.sol";
import "contracts/Payable.sol";


contract EasyExchange is Payable {
    EasyToken tokenContract;
    uint256 public sellPrice; // Price for 1 token in wei
    uint256 public buyPrice;
    address owner;                                               
    mapping(address => uint256) sendedByUserETH;

    event Bought(address buyer, uint256 amount, uint256 BuyPrice);
    event Sold(address solder, uint256 amount, uint256 SellPrice);
    receive() external payable {
        sendedByUserETH[msg.sender] += msg.value;
    }
    constructor(address tokenAddress) public {
        tokenContract = EasyToken(tokenAddress);
        owner = msg.sender;
    }
    function setSellPrice(uint256 _sellPrice) public  {
        require(msg.sender == owner, "Sender is not owner!");
        sellPrice = _sellPrice;
    }

    function getSellPrice() public returns(uint256){
        return sellPrice;
    }

    function setBuyPrice(uint256 _buyPrice) public {
        require(msg.sender == owner, "Sender is not owner!");
        buyPrice = _buyPrice;
    }

    function getBuyPrice() public returns(uint256){
        return buyPrice;
    }

    function sellTokens(uint256 amount, address payable sender) payable public{
        require(address(this).balance >= amount * sellPrice, "Contract dont have enough ETH");
        tokenContract.burn(sender, amount);
        sender.transfer(amount * sellPrice);
        emit Sold(msg.sender, amount, sellPrice);
    }
    function payedSellTokens(uint256 amount, address payable sender) payable public{
        require(currentContextAddress != address(0));
        require(address(this).balance >= amount * sellPrice, "Contract dont have enough ETH");
        require(tokenContract.balanceOf(currentContextAddress) >= amount, "Sender dont have enough tokens");
        tokenContract.burn(currentContextAddress, amount);
        sender.transfer(amount * sellPrice);
        currentContextAddress = address(0);
        emit Sold(msg.sender, amount, sellPrice);
    }

    function buyTokens(uint256 amount) payable public{
        require(msg.value == amount * buyPrice, "Not enough money sended");
        uint256 thisTokenBalance = tokenContract.balanceOf(address(this));
        if(thisTokenBalance < amount) {
            tokenContract.mint(address(this), amount - thisTokenBalance);
        }
        tokenContract.transfer(msg.sender, amount);
        emit Bought(msg.sender, amount, buyPrice);
    }   

     function payedBuyTokens(uint256 amount) payable public{
        require(currentContextAddress != address(0));
        require(sendedByUserETH[currentContextAddress] >= amount * buyPrice, "Not enough money sended");
        uint256 thisTokenBalance = tokenContract.balanceOf(address(this));
        if(thisTokenBalance < amount) {
            tokenContract.mint(address(this), amount - thisTokenBalance);
        }
        tokenContract.transfer(currentContextAddress, amount);
        sendedByUserETH[currentContextAddress] -= amount * buyPrice;
        currentContextAddress = address(0);
        emit Bought(msg.sender, amount, buyPrice);
    }   
}