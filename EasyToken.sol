pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/Payable.sol";

contract EasyToken is ERC20, AccessControl, Payable {
    bytes32 public constant EXCHANGER_ROLE = keccak256("EXCHANGER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint8 decimal;
    uint256 public tokenCommission;
    constructor(uint8 _decimal,string memory name,string memory symb,uint256 commission) public ERC20(name, symb) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _decimal = decimal;
        tokenCommission = commission;
    }
    
    function setTokenCommision(uint256 newCommission) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "No rights");
        tokenCommission = newCommission;
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || 
            hasRole(EXCHANGER_ROLE, msg.sender));
        _mint(to, amount);
    }

    function payedTransfer(address _to, uint256 _value) public returns(bool){
        require(balanceOf(currentContextAddress) >= tokenCommission + _value, "Not enough tokens");
        require(currentContextAddress != address(0), "Address is 0");
        _transfer(currentContextAddress, _to, _value); 
        _burn(currentContextAddress, tokenCommission); 
        currentContextAddress = address(0);
        return true;
    }
    function burn(address from, uint256 amount) public {
        require(hasRole(BURNER_ROLE, msg.sender) || hasRole(EXCHANGER_ROLE, msg.sender), "Caller is not a burner");
        _burn(from, amount);
    }
}