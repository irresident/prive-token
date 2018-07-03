pragma solidity ^0.4.21;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../token/PriveToken.sol";

contract PrivePresale is Ownable, Crowdsale {
    using SafeMath for uint256;

    uint256 constant internal TOKEN_PRICE_DECIMALS = 1;
    uint256 constant internal TOKEN_PRICE_DIVISOR = 10 ** uint256(TOKEN_PRICE_DECIMALS);
    uint256 constant internal DISCOUNTED_TOKEN_PRICE = 7;
    uint256 constant internal FULL_TOKEN_PRICE = 10;

    bool public closed = false;
    uint256 public tokensSold = 0;
    uint256 public discountedTokenCap = 6500000 * 1 ether;
    uint256 public tokenCap = 13500000 * 1 ether;
    uint256 public minimumPurchase;

    uint256 internal rateDivisor;

    event PresaleClosed();
    event EthUSDRateChange(uint256 newRate);
    event MinimumPurchaseChange(uint256 newMinimum);

    /**
     * @param _wallet Address of the wallet to send funds to.
     * @param _token Address of the token being sold.
     * @param _minimumPurchase Minimum amount of wei required to make a purchase.
     * @param _rate Initial ETH to USD exchange rate multiplied by 10 ^ _rateDecimals.
     * @param _rateDecimals The number of decimal places after decimal point used for ETH to USD exchange rate.
     */
    constructor(address _wallet, PriveToken _token, uint256 _minimumPurchase, uint256 _rate, uint8 _rateDecimals) public
        Crowdsale(_rate, _wallet, _token)
    {
        require(discountedTokenCap < tokenCap);
        require(_rateDecimals >= 2 && _rateDecimals <= 18);
        require(_minimumPurchase > 0);
        minimumPurchase = _minimumPurchase;
        rateDivisor = 10 ** uint256(_rateDecimals);
    }


    /**
     * @dev Sets the ETH to USD exchange rate.
     * @param _rate ETH to USD exchange rate multiplied by 10 ^ _rateDecimals
     */
    function setRate(uint256 _rate) onlyOwner public {
        require(!closed);
        require(_rate > 0);
        rate = _rate;
        emit EthUSDRateChange(_rate);
    }


    /**
     * @dev Sets the minimum amount of wei required to purchase.
     * @param _minimumPurchase Minimum amount of wei allowed to purchase tokens.
     */
    function setMinimumPurchase(uint256 _minimumPurchase) onlyOwner public {
        require(!closed);
        require(_minimumPurchase > 0);
        minimumPurchase = _minimumPurchase;
        emit MinimumPurchaseChange(_minimumPurchase);
    }

    /**
     * Closes the presale from further buying.
     */
    function close() onlyOwner public {
        require(!closed);
        closed = true;
        emit PresaleClosed();
    }

    /**
     * @dev Validation of an incoming purchase. Overriden to ensure we can make the sale.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(!closed);
        require(tokensSold < tokenCap);
        require(_weiAmount >= minimumPurchase);
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }


    /**
     * @dev Computes how many tokens for ether for given token price.
     * @param _weiAmount Value in wei to be converted into tokens
     * @param _tokenPrice Price of 1 token in tenths of USD (e.g. 10 is $1)
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _computeTokenAmount(uint256 _weiAmount, uint256 _tokenPrice) internal view returns (uint256) {
        uint256 divisor = _tokenPrice.mul(rateDivisor);
        return _weiAmount.mul(rate).mul(TOKEN_PRICE_DIVISOR).div(divisor);
    }

    /**
     * @dev Overridden to implement our own conversion from ETH into Prive tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokenAmount = 0;
        if (tokensSold < discountedTokenCap) {
            // discount tokens available, calculate how many discounted tokens are bought
            uint256 discountedAmount = _computeTokenAmount(_weiAmount, DISCOUNTED_TOKEN_PRICE);
            uint256 newTokensSold = tokensSold.add(discountedAmount);
            if (newTokensSold > discountedTokenCap) {
                // sold tokens + tokens to buy is over the discounted token cap - convert overflow to full priced tokens
                uint256 overflow = newTokensSold.sub(discountedTokenCap);
                uint256 fullPricedOverflow = overflow.mul(DISCOUNTED_TOKEN_PRICE).div(FULL_TOKEN_PRICE);
                tokenAmount = discountedAmount.sub(overflow).add(fullPricedOverflow);

            } else {
                tokenAmount = discountedAmount;
            }
        } else {
            // no discounted tokens available, buy tokens at full price
            tokenAmount = _computeTokenAmount(_weiAmount, FULL_TOKEN_PRICE);
        }
        require(tokenAmount > 0); // if it's 0 just rollback
        require(tokensSold.add(tokenAmount) <= tokenCap); // if it's over the cap also rollback
        return tokenAmount;
    }

    /**
     * @dev Overriden to provide Prive tokens via minting API on the token.
     * @param _beneficiary Token purchaser
     * @param _tokenAmount Number of tokens to be minted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        require(PriveToken(token).mint(_beneficiary, _tokenAmount));
        tokensSold = tokensSold.add(_tokenAmount);
    }
}
