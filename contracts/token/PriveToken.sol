pragma solidity ^0.4.21;

import "openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/ownership/Whitelist.sol";

/**
 * @title Test ERC20 token
 */
contract PriveToken is Ownable, DetailedERC20, StandardToken, Whitelist {

    address public crowdsale = address(0);
    // Tokens are not initially tradeable until enabled for trading, then they are tradeable forever
    bool public tradable = false;

    // Maximum amount of tokens that can be minted
    uint256 public maximumSupply;

    event Mint(address indexed to, uint256 amount);
    event CrowdsaleChanged(address indexed previousCrowdsale, address indexed newCrowdsale);
    event TradingEnabled();

    constructor() public
        DetailedERC20("Privé Token", "PRIVE", 18)
    {
        maximumSupply = 50000000 * 1 ether;
    }

    modifier onlyOwnerOrCrowdsale() {
        require(msg.sender == owner || msg.sender == crowdsale);
        _;
    }

    /**
     * @dev Allows the current owner to change address of the crowdsale contract.
     * @param _crowdsale The address to set for the crowdsale.
     */
    function setCrowdsale(address _crowdsale) public onlyOwner {
        address prevCrowdsale = crowdsale;
        crowdsale = _crowdsale;
        emit CrowdsaleChanged(prevCrowdsale, _crowdsale);
    }

    /**
     * @dev Function to mint tokens up to a defined cap.
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwnerOrCrowdsale public returns (bool) {
        require(totalSupply_.add(_amount) <= maximumSupply);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }


    /**
     * @dev Allow trading - called only once, when ICO starts.
     */
    function enableTrading() onlyOwner public {
        require(tradable == false);
        tradable = true;
        emit TradingEnabled();
    }

    /**
     * @dev Throws if called when token is not tradable.
     * @dev Only addresses on whitelist can trade.
     */
    modifier canTrade() {
        require(tradable || whitelist[msg.sender]);
        _;
    }

    /**
     * @dev Overridden to apply canTrade modifier.
     */
    function transfer(address _to, uint256 _value) public canTrade returns (bool) {
        return super.transfer(_to, _value);
    }

    /*
     * transferFrom is not overridden because it can always be executed -> trading is controlled via approval methods.
     */

    /**
     * @dev Overridden to apply canTrade modifier.
     */
    function approve(address _spender, uint256 _value) public canTrade returns (bool) {
        return super.approve(_spender, _value);
    }

    /**
     * @dev Overridden to apply canTrade modifier.
     */
    function increaseApproval(address _spender, uint _addedValue) public canTrade returns (bool) {
        return super.increaseApproval(_spender, _addedValue);
    }

    /**
     * @dev Overridden to apply canTrade modifier.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public canTrade returns (bool) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

