pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../token/IToken.sol";
import "../token/ICrowdsale.sol";


/**
 * @title PriveCrowdsale
 * @author Irresident Limited - www.irresident.io
 * @notice PriveCrowdsale is a contract for managing a long term crowdsale of Prive tokens.
 * It allows token buyers to purchase Prive tokens with ether, and it enables Irresident to control token price and
 * have multiple token sale rounds over a longer period of time.
 */
contract PriveCrowdsale is ICrowdsale, Ownable {
    using SafeMath for uint256;

    // The token being sold
    IToken public token;

    // maximum allowed supply of tokens - a purposefully redundant copy of token.maximumSupply
    uint256 public maximumTokenSupply;

    // Address where funds are collected
    address public wallet;

    // Minimum amount of wei required to perform a purchase
    uint256 public minimumPurchase;

    // Price for one token denominated in ether
    uint256 public price;

    // ETHUSD rate for the given price as a 10**4 fixed point value - provided for reference only
    uint256 public ethUsdRate;

    // time when price was last changed as seconds since unix epoch (00:00 Jan 1, 1970)
    uint public priceChangeTime;

    // Total amount of wei raised
    uint256 public weiRaised;

    // Amount of Prive tokens sold by this crowdsale
    uint256 public tokensSold;

    // maximum amount of tokens allowed to be sold
    uint256 public tokenSaleCap;

    // currently reserved supply of tokens including current round and all special offers
    uint256 public reservedTokenSupply;

    // True if selling is temporarily stopped
    bool public saleStopped;

    // Maximum number of tokens that can be sold during current round
    uint256 public roundTokenCap;

    // Amount of Prive tokens sold in current round
    uint256 public roundTokensSold;

    // Whether crowdsale is active and attached to the token.
    bool public active;


    // Special offer data
    struct SpecialOffer {
        uint256 endTime;    // time when offer expires as seconds since unix epoch (00:00 Jan 1, 1970)
        uint256 price;      // price for one token denominated in ether
        uint256 minTokens;  // minimum tokens purchaser must buy to take advantage of the offer
        uint256 maxTokens;  // optional or 0 if no maximum
    }

    // Special offer linked list data
    struct ListLinks {
        address prevEntry; // address of previous entry or 0 if none
        address nextEntry; // address of the next entry or 0 if none
    }

    // maps client addresses to a doubly linked list links
    // node 0x0 links point to first (nexEntry) and last (prevEntry) entry
    mapping(address => ListLinks) internal specialOffersLinks;

    // maps client addresses to special offers
    mapping(address => SpecialOffer) public specialOffers;


    /**
     * @notice Event for activation logging.
     */
    event Activated();

    /**
     * @notice Event for deactivation logging.
     */
    event Deactivated();

    /**
     * @notice Event for current token supply cap change logging.
     * @param previousCap previous supply cap
     * @param newCap new token supply cap
     */
    event TokenSaleCapChanged(uint256 previousCap, uint256 newCap);

    /**
     * @notice Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param price price at the time of purchase
     * @param value wei paid for purchase
     * @param amount amount of tokens purchased
     * @param refund the amount of ETH refunded, if purchase was partially filled
     * @param ethUsdRate the ETHUSD rate used to calculate price
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 price,
        uint256 value,
        uint256 amount,
        uint256 refund,
        uint256 ethUsdRate
    );

    /**
     * @notice Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param price price at the time of purchase
     * @param value wei paid for purchase
     * @param amount amount of tokens purchased
     * @param refund the amount of ETH refunded, if purchase was partially filled
     */
    event SpecialOfferTokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 price,
        uint256 value,
        uint256 amount,
        uint256 refund
    );

    /**
     * @notice Event for minimum purchase amount change logging.
     * @param minimumPurchase new minimum purchase amount
     */
    event MinimumPurchaseChange(uint256 minimumPurchase);


    /**
     * @notice Event for price change logging.
     * @param price price for one token denominated in ether
     * @param ethUsdRate ETHUSD conversion rate used to calculate the price as a 10**4 fixed point value
     */
    event PriceChange(uint256 price, uint256 ethUsdRate);

    /** @notice Event for stopping active crowdsale logging. */
    event SaleStopped();

    /** @notice Event for resuming stopped crowdsale logging. */
    event SaleResumed();

    /**
     * @notice Event for start of next round of token sales.
     * NOTE: no event is sent for the initial round started by creation of the contract.
     * @param roundCap maximum number of tokens allowed to be sold in current round.
     */
    event NewRoundStarted(uint256 roundCap);

    /**
     * @notice Event for ending a round of token sales.
     * @param roundTokensSold number of tokens sold during this round
     * @param roundTokenCap maximum number of tokens to be sold in the ended round
     */
    event RoundEnded(uint256 roundTokensSold, uint256 roundTokenCap);

    /**
     * @notice Event for start of special offer.
     * @param purchaser who paid for the tokens
     * @param price price at the time of purchase
     * @param endTime time when offer ends as seconds since unix epoch (00:00 Jan 1, 1970)
     * @param minTokens minimum number of tokens purchaser needs to buy to make use of special offer
     * @param maxTokens maximum number of tokens purchaser can buy using special offer, or 0 for no limit
     */
    event SpecialOfferStarted(
        address indexed purchaser,
        uint256 price,
        uint256 endTime,
        uint256 minTokens,
        uint256 maxTokens
    );

    /**
     * @notice Event for end of special offer.
     * @param purchaser address for which special offer ended
     */
    event SpecialOfferEnded(address indexed purchaser);

    /**
     * @notice Crowdsale constructor.
     * @param _wallet address of the wallet to send funds to.
     * @param _token address of the token being sold.
     * @param _cap maximum number of tokens that can be sold by this crowdsale.
     * @param _minimumPurchase minimum amount of wei required to make a purchase.
     * @param _price price for one token denominated in ether
     * @param _ethUsdRate ETHUSD conversion rate used to calculate the price as a 10**4 fixed point value
     * @param _roundCap cap for initial round of token sale, or 0 for no initial sale
     */
    constructor(
        address _wallet, IToken _token, uint256 _cap, uint256 _minimumPurchase,
        uint256 _price, uint256 _ethUsdRate, uint256 _roundCap
    ) public {
        require(_wallet != address(0));
        require(_token != address(0));
        require(_minimumPurchase > 0);
        require(_price > 0);
        require(_cap >= _roundCap);
        maximumTokenSupply = _token.maximumSupply();
        require(_cap <= maximumTokenSupply);
        wallet = _wallet;
        token = _token;
        tokenSaleCap = _cap;
        minimumPurchase = _minimumPurchase;
        price = _price;
        ethUsdRate = _ethUsdRate;
        priceChangeTime = now;
        roundTokenCap = _roundCap;
        roundTokensSold = 0;
        reservedTokenSupply = _roundCap;
        weiRaised = 0;
        tokensSold = 0;
        saleStopped = false;
        active = false;
    }
    // -----------------------------------------
    // ICrowdsale interface
    // -----------------------------------------

    /**
     * @notice Allows only token to access a particular function.
     */
    modifier onlyToken() {
        require(token == msg.sender);
        _;
    }

    /**
     * @notice Allows only token or owner to access a particular function.
     */
    modifier onlyTokenOrOwner() {
        require(token == msg.sender || owner == msg.sender);
        _;
    }

    /**
     * @notice Allows a particular function to be called only after crowdsale has been activated.
     */
    modifier ifActive() {
        require(active);
        _;
    }

    /**
     * @notice Called by token to activate crowdsale for it's intended token.
     * @dev Throws if there are not enough tokens to satisfy reserved tokens requirements or if caller was not token.
     * @param _soldSupply amount of tokens sold by crowdsale(s)
     * @param _totalSupply amount of tokens in total minted
     * @return required crowdsale cap - amount of tokens allocated to selling by crowdsale
     */
    function activate(uint256 _soldSupply, uint256 _totalSupply) external onlyToken returns(uint256) {
        assert(!active);
        // make sure there are enough tokens to meet reserved tokens
        require(_soldSupply.add(reservedTokenSupply) <= tokenSaleCap);
        require(maximumTokenSupply.sub(_totalSupply) >= reservedTokenSupply);
        active = true;
        emit Activated();
        return tokenSaleCap;
    }

    /**
     * @notice Called by token to deactivate crowdsale.
     * @dev Throws if caller is not contract or crowdsale owner
     */
    function deactivate() external onlyTokenOrOwner {
        if (active) {
            active = false;
            emit Deactivated();
        }
    }

    // -----------------------------------------
    // Public interface
    // -----------------------------------------

    /**
     * @notice Check if overall token cap has been reached.
     * @return Returns true if crowdsale token cap has been reached, or false otherwise.
     */
    function tokenSaleCapReached() public view returns(bool) {
        return tokenSaleCap <= token.soldSupply();
    }

    /**
     * @notice Check if current round's cap has been reached.
     * @return Returns true if current round's token cap has been reached, or false otherwise.
     */
    function roundCapReached() public view returns(bool) {
        return roundTokenCap <= roundTokensSold;
    }

    /**
     * @notice Sets the number of tokens available for sale. The remainder up to maximum supply are reserved
     *         for private use.
     * @dev Throws if new cap is 0, lower than sumo of tokens sold and reserved tokens or greater than difference
     *      of maximum supply and tokens given away.
     * @param _cap new token supply cap
     */
    function setTokenSaleCap(uint256 _cap) external onlyOwner {
        require(_cap > 0);
        require(_cap >= token.soldSupply().add(reservedTokenSupply));
        require(_cap <= maximumTokenSupply.sub(token.usedPrivateSupply()));
        if (active) {
            token.setCrowdsaleCap(_cap);
        }
        uint256 prevCap = tokenSaleCap;
        tokenSaleCap = _cap;
        emit TokenSaleCapChanged(prevCap, _cap);
    }

    /**
     * @notice Sets the minimum amount of wei required to purchase.
     * @dev Throws if minimum purchase is 0.
     * @param _minimumPurchase Minimum amount of wei allowed to purchase tokens.
     */
    function setMinimumPurchase(uint256 _minimumPurchase) external onlyOwner {
        require(_minimumPurchase > 0);
        minimumPurchase = _minimumPurchase;
        emit MinimumPurchaseChange(_minimumPurchase);
    }

    /**
     * @notice Sets the PRIVEETH price.
     * @param _price price for one token denominated in ether
     * @param _ethUsdRate ETHUSD conversion rate used to calculate the price as a 10**4 fixed point value
     */
    function setPrice(uint256 _price, uint256 _ethUsdRate) public onlyOwner {
        require(_price > 0);
        price = _price;
        ethUsdRate = _ethUsdRate;
        priceChangeTime = now;
        emit PriceChange(_price, _ethUsdRate);
    }


    /**
     * @notice Starts a new round of token sale
     * @dev If requested round cap is over available token supply it will get capped to available tokens.
     * @param _price price for one token denominated in ether
     * @param _ethUsdRate ETHUSD conversion rate used to calculate the price as a 10**4 fixed point value
     * @param _roundCap cap for the round of token sale, or 0 to disable selling
     * @param _flexibleRoundCap allow round cap to be reduced if above token cap when combined with tokens sold;
     *                          otherwise throw
     */
    function startNewRound(
        uint256 _price, uint256 _ethUsdRate, uint256 _roundCap, bool _flexibleRoundCap
    ) external onlyOwner {
        require(_price > 0);
        assert(!tokenSaleCapReached());
        uint256 prevRoundCap = roundTokenCap;
        uint256 prevRoundSold = roundTokensSold;
        uint256 unusedReservation = prevRoundCap.sub(prevRoundSold);
        // cap - sold - (allReserved - unusedReservation)
        uint256 availableCap = tokenSaleCap.sub(token.soldSupply()).add(unusedReservation).sub(reservedTokenSupply);
        uint256 newRoundCap;
        if (availableCap < _roundCap) {
            require(_flexibleRoundCap);
            newRoundCap = availableCap;

        } else {
            newRoundCap = _roundCap;
        }
        reservedTokenSupply = reservedTokenSupply.sub(unusedReservation).add(newRoundCap);
        assert(reservedTokenSupply <= tokenSaleCap);
        emit RoundEnded(prevRoundSold, prevRoundCap);
        setPrice(_price, _ethUsdRate);
        roundTokensSold = 0;
        roundTokenCap = newRoundCap;
        emit NewRoundStarted(newRoundCap);
    }

    /**
     * @notice Stops token sale.
     * @dev Will throw is sale is already stopped.
     */
    function stopSale() external onlyOwner {
        assert(!saleStopped);
        saleStopped = true;
        emit SaleStopped();
    }

    /**
     * @notice Resumes token sale if stopped.
     * @dev Will throw is sale is not previously stopped.
     */
    function resumeSale() external onlyOwner {
        assert(saleStopped);
        saleStopped = false;
        emit SaleResumed();
    }


    /**
     * @notice Starts a special offer for specified purchaser. If there is an ongoing special offer for that purchaser
     * it's overwritten by the new offer.
     * @dev Will throw if price or maximum tokens are 0 or maximum tokens is lower than minimum tokens.
     * @param _purchaser purchaser that benefits from special offer
     * @param _price price for one token denominated in ether
     * @param _offerEndTime time when offer ends as seconds since unix epoch (00:00 Jan 1, 1970)
     * @param _minTokens minimum number of tokens purchaser needs to buy to make use of special offer
     * @param _maxTokens maximum number of tokens purchaser can buy using special offer
     */
    function startSpecialOffer(
        address _purchaser, uint256 _price, uint256 _offerEndTime, uint256 _minTokens, uint256 _maxTokens
    ) external onlyOwner {
        require(_purchaser != address(0x0));
        require(_offerEndTime > now);
        require(_price > 0);
        require(_maxTokens > 0);
        require(_minTokens <= _maxTokens);
        // if offer doesn't exist - create new links, otherwise we'll just replace the data
        if (specialOffers[_purchaser].endTime == 0) {
            // just verify and update reserved token supply
            reservedTokenSupply = reservedTokenSupply.add(_maxTokens);
            assert(reservedTokenSupply.add(token.soldSupply()) <= tokenSaleCap);

            // new head node, so reset previous entry to 0
            specialOffersLinks[_purchaser].prevEntry = 0x0;
            // new head node, so put old head node as next entry
            address oldFirstEntry = specialOffersLinks[0x0].nextEntry;
            specialOffersLinks[_purchaser].nextEntry = oldFirstEntry;

            // insert as nextEntry to list head
            specialOffersLinks[0x0].nextEntry = _purchaser;
            // insert as prevEntry to previous head - note this makes [0x0].prevEntry point to end of the list
            specialOffersLinks[oldFirstEntry].prevEntry = _purchaser;
        } else {
            // remove previous offer's reservation and add new offer's reservation on token supply
            uint256 previouslyReserved = specialOffers[_purchaser].maxTokens;
            reservedTokenSupply = reservedTokenSupply.sub(previouslyReserved).add(_maxTokens);
            assert(reservedTokenSupply.add(token.soldSupply()) <= tokenSaleCap);
        }
        SpecialOffer memory offer = SpecialOffer(_offerEndTime, _price, _minTokens, _maxTokens);
        specialOffers[_purchaser] = offer;
        emit SpecialOfferStarted(_purchaser, _price, _offerEndTime, _minTokens, _maxTokens);
    }

    /**
     * @notice Ends special offer for specified purchaser.
     * @param _purchaser address of the purchaser to remove the special offer from
     */
    function endSpecialOffer(address _purchaser) external onlyOwner returns (bool) {
        return _endSpecialOffer(_purchaser);
    }

    /**
     * @notice Ends special offer for specified purchasers.
     * @param _purchasers addresses of the purchasers to remove the special offer from
     */
    function endSpecialOffers(address[] _purchasers) external onlyOwner returns(bool success) {
        for (uint256 i = 0; i < _purchasers.length; i++) {
            if (_endSpecialOffer(_purchasers[i])) {
                success = true;
            }
        }
    }

    /**
     * @notice Ends special offer for specified purchaser.
     * @param _purchaser address of the purchaser to remove the special offer from
     */
    function _endSpecialOffer(address _purchaser) internal returns (bool success) {
        require(_purchaser != address(0x0));
        if (specialOffers[_purchaser].endTime > 0) {
            // remove offer from reserved pool
            reservedTokenSupply = reservedTokenSupply.sub(specialOffers[_purchaser].maxTokens);

            // link node neighbors
            address prevEntry = specialOffersLinks[_purchaser].prevEntry;
            address nextEntry = specialOffersLinks[_purchaser].nextEntry;
            specialOffersLinks[prevEntry].nextEntry = nextEntry;
            specialOffersLinks[nextEntry].prevEntry = prevEntry;

            // cleanup
            delete specialOffers[_purchaser];
            delete specialOffersLinks[_purchaser];
            emit SpecialOfferEnded(_purchaser);
            success = true;
        }
    }

    /**
     * @notice Finds up to ten expired special offers and returns addresses they apply to.
     * @dev We use fixed array size due to Solidity limitations on dynamic arrays as return values.
     * @return count number of addresses found with expired special offers
     * @return addresses up to ten addresses with expired special offers, with 0 in unused array slots
     */
    function findExpiredOffers() external onlyOwner view returns (uint count, address[10] addresses) {
        count = 0;
        address ptr = specialOffersLinks[0x0].nextEntry;
        uint256 rightNow = now;
        while (ptr != 0 && count < 10) {
            if (specialOffers[ptr].endTime <= rightNow) {
                addresses[count] = ptr;
                count += 1;
            }
            ptr = specialOffersLinks[ptr].nextEntry;
        }
    }

    /**
     * @notice Returns up to twenty special offers.
     * @dev We use fixed array size due to Solidity limitations on dynamic arrays as return values.
     * @return count of special offers returned
     * @return special offers
     */
    function getSpecialOffers() external onlyOwner view returns (
        uint count,
        address[20] addresses, bool[20] expired, uint256[20] endTimes, uint256[20] prices,
        uint256[20] minTokens, uint256[20] maxTokens
    ) {
        count = 0;
        address ptr = specialOffersLinks[0x0].nextEntry;
        uint256 rightNow = now;
        while (ptr != 0 && count < 20) {
            addresses[count] = ptr;
            expired[count] = specialOffers[ptr].endTime <= rightNow;
            endTimes[count] = specialOffers[ptr].endTime;
            prices[count] = specialOffers[ptr].price;
            minTokens[count] = specialOffers[ptr].minTokens;
            maxTokens[count] = specialOffers[ptr].maxTokens;
            count += 1;
            ptr = specialOffersLinks[ptr].nextEntry;
        }
    }

    /**
     * @notice fallback function - Buys tokens for the received amount of ETH. In case of not enough tokens available
     * for sale, the purchase is partially filled and the rest of ETH is refunded to the sender address.
     */
    function () external payable { // solhint-disable-line no-complex-fallback
        require(msg.data.length == 0);
        buyTokensFor(msg.sender, true);
    }

    /**
     * @notice Purchase tokens for a beneficiary
     * @param _beneficiary address to receive token purchase
     * @param _allowPartialFill allows buying less tokens than requested if not enough tokens available and refunds
     *                          the difference
     */
    function buyTokensFor(address _beneficiary, bool _allowPartialFill) public payable {
        _purchaseTokensFor(msg.sender, _beneficiary, 0, msg.value, _allowPartialFill);
    }

    /**
     * @notice Purchase tokens for a beneficiary only at specified price.
     * @param _requestedPrice the exact price expected for this purchase
     * @param _allowPartialFill allows buying less tokens than requested if not enough tokens available and refunds
     *                          the difference
     */
    function buyTokensAtPrice(uint256 _requestedPrice, bool _allowPartialFill) public payable {
        require(_requestedPrice > 0);
        buyTokensAtPriceFor(msg.sender, _requestedPrice, _allowPartialFill);
    }

    /**
     * @notice Purchase tokens for a beneficiary only at specified price.
     * @param _beneficiary address to receive token purchase
     * @param _requestedPrice the exact price expected for this purchase
     * @param _allowPartialFill allows buying less tokens than requested if not enough tokens available and refunds
     *                          the difference
     */
    function buyTokensAtPriceFor(address _beneficiary, uint256 _requestedPrice, bool _allowPartialFill) public payable {
        require(_requestedPrice > 0);
        _purchaseTokensFor(msg.sender, _beneficiary, _requestedPrice, msg.value, _allowPartialFill);
    }


    // -----------------------------------------
    // Internal interface
    // -----------------------------------------

    /**
     * @notice Purchase tokens.
     * @param _purchaser address performing token purchase
     * @param _beneficiary address to receive token purchase
     * @param _weiAmount amount of wei to be used for purchase
     * @param _allowPartialFill allows buying less tokens than requested if not enough tokens available and refunds
     *                          the difference
     */
    function _purchaseTokensFor(
        address _purchaser, address _beneficiary, uint256 _requestedPrice, uint256 _weiAmount, bool _allowPartialFill
    ) internal ifActive {
        require(_weiAmount > 0);
        require(_beneficiary != address(0));
        assert(!saleStopped);

        uint256 specialOfferEndTime = specialOffers[_purchaser].endTime;
        if (specialOfferEndTime > 0 && specialOfferEndTime > now) {
            require(_requestedPrice == 0 || _requestedPrice == specialOffers[_purchaser].price);
            _purchaseTokensOnSpecialOffer(_purchaser, _beneficiary, _weiAmount, _allowPartialFill);
        } else {
            require(_requestedPrice == 0 || _requestedPrice == price);
            _purchaseTokensAtStandardPrice(_purchaser, _beneficiary, _weiAmount, _allowPartialFill);
        }
    }

    /**
     * @notice Purchase tokens on behalf of beneficiary at special offer price.
     * @param _purchaser address performing token purchase
     * @param _beneficiary address to receive token purchase
     * @param _weiAmount amount of wei to be used for purchase
     * @param _allowPartialFill allows buying less tokens than requested if not enough tokens available and refunds
     *                          the difference
     */
    function _purchaseTokensOnSpecialOffer(
        address _purchaser, address _beneficiary, uint256 _weiAmount, bool _allowPartialFill
    ) internal {
        assert(!tokenSaleCapReached());

        uint256 refund = 0;
        uint256 weiAmount = _weiAmount;
        uint256 _price = specialOffers[_purchaser].price;
        assert(_price > 0);
        uint256 tokens = _ethToToken(weiAmount, _price);
        uint256 _minTokens = specialOffers[_purchaser].minTokens;
        require(tokens >= _minTokens);
        uint256 _maxTokens = specialOffers[_purchaser].maxTokens;

        if (_allowPartialFill) {
            // flexible mode - buy tokens up to cap, refund extra ETH
            // must not go over special offer
            uint256 overflow = _calcTokensOverCap(tokens, _maxTokens, overflow);
            // overall tokens must not go over cap
            overflow = _calcTokensOverCap(token.soldSupply().add(tokens), tokenSaleCap, overflow);

            if (overflow > 0) {
                tokens = tokens.sub(overflow);
                refund = _tokenToEth(overflow, _price);
                weiAmount = _weiAmount.sub(refund);
            }
            assert(tokens >= _minTokens);
        }
        assert(weiAmount > 0);
        assert(tokens > 0);
        assert(tokens <= _maxTokens);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);
        // reservedTokenSupply will be freed when special offer is ended below in this function

        // mint token and require true as result then trigger purchase event
        assert(token.mint(_beneficiary, tokens));

        emit SpecialOfferTokenPurchase(_purchaser, _beneficiary, price, weiAmount, tokens, refund);
        // special offer is consumed once used
        _endSpecialOffer(_purchaser);

        // forward funds to wallet
        wallet.transfer(weiAmount);
        // refund if overbought above cap
        if (refund > 0) {
            _purchaser.transfer(refund);
        }
    }

    /**
     * @notice Purchase tokens on behalf of beneficiary at standard price.
     * @param _purchaser address performing token purchase
     * @param _beneficiary address to receive token purchase
     * @param _weiAmount amount of wei to be used for purchase
     * @param _allowPartialFill allows buying less tokens than requested if not enough tokens available and refunds
     *                          the difference
     */
    function _purchaseTokensAtStandardPrice(
        address _purchaser, address _beneficiary, uint256 _weiAmount, bool _allowPartialFill
    ) internal {
        require(_weiAmount >= minimumPurchase); // this also ensures _weiAmount != 0
        assert(!tokenSaleCapReached());
        assert(!roundCapReached());
        assert(price > 0);
        uint256 weiAmount = _weiAmount;
        // calculate token amount to be created
        uint256 tokens = _ethToToken(weiAmount, price);
        uint256 refund = 0;
        if (_allowPartialFill) {
            // flexible mode - buy tokens up to cap, refund extra ETH
            // round tokens must not go over cap
            uint256 overflow = _calcTokensOverCap(roundTokensSold.add(tokens), roundTokenCap, 0);
            // overall tokens must not go over cap
            overflow = _calcTokensOverCap(token.soldSupply().add(tokens), tokenSaleCap, overflow);

            if (overflow > 0) {
                tokens = tokens.sub(overflow);
                refund = _tokenToEth(overflow, price);
                weiAmount = _weiAmount.sub(refund);
            }
        }
        // should never fail, but exist for just in case
        assert(weiAmount > 0);
        assert(tokens > 0);
        roundTokensSold = roundTokensSold.add(tokens);
        assert(roundTokensSold <= roundTokenCap);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);
        reservedTokenSupply = reservedTokenSupply.sub(tokens);

        // mint token and require true as result then trigger purchase event
        assert(token.mint(_beneficiary, tokens));
        emit TokenPurchase(_purchaser, _beneficiary, price, weiAmount, tokens, refund, ethUsdRate);

        // forward funds to wallet
        wallet.transfer(weiAmount);
        // refund if overbought above cap
        if (refund > 0) {
            _purchaser.transfer(refund);
        }

        if (roundTokensSold >= roundTokenCap) {
            emit RoundEnded(roundTokensSold, roundTokenCap);
        }
    }

    /**
     * @notice Converts wei amount to equivalent amount of tokens using current token price.
     * @param _weiAmount ether amount in wei to convert to tokens
     * @param _price price for one token denominated in ether
     * @return amount of tokens corresponding to given wei amount
     */
    function _ethToToken(uint256 _weiAmount, uint256 _price) internal pure returns (uint256) {
        // token = weiAmount * 1 ether / price; multiply by 1 ether because price is 10**18 fixed point value
        return _weiAmount.mul(1 ether).div(_price);
    }

    /**
     * @notice Converts token amount to equivalent wei amount using current token price.
     * @param _tokens amount of tokens to convert to wei
     * @param _price price for one token denominated in ether
     * @return amount of wei corresponding to given amount of tokens
     */
    function _tokenToEth(uint256 _tokens, uint256 _price) internal pure returns(uint256) {
        // weiAmount = token * price / 1 ether; divide by 1 ether because price is 10**18 fixed point value
        return _tokens.mul(_price).div(1 ether);
    }

    /**
     * @notice Returns the amount of token overflow beyond the cap or current overflow if it's greater.
     * @param _tokens number of tokens sold including current purchase
     * @param _cap maximum number of tokens available for sale
     * @param _currentOverflow amount of overflow already detected, or 0 if none
     * @return the larger value between calculated and current overflow, or 0 if no overflow detected
     */
    function _calcTokensOverCap(
        uint256 _tokens, uint256 _cap, uint256 _currentOverflow
    ) internal pure returns(uint256) {
        if (_tokens > _cap) {
            uint256 overflow = _tokens - _cap;
            if (overflow > _currentOverflow) {
                return overflow;
            }
        }
        return _currentOverflow;
    }
}
