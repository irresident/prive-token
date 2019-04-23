pragma solidity 0.4.24;


/**
 * @title IToken
 * @author Irresident Limited - www.irresident.io
 * @notice Interface defining token's API to be used by its crowdsale(s).
 */
contract IToken {
    /**
     * @notice Function to mint tokens and triggers Mint and Transfer events on success.
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) external returns (bool);

    /**
     * @notice Sets the maximum amount of tokens that can be sold by currently active crowdsale. The remaining tokens
     * up to maximum supply can be freely minted.
     * @dev Throws if called by non-crowdsale
     * @param _amount crowdsale cap amount
     */
    function setCrowdsaleCap(uint256 _amount) external;

    /**
     * @notice Total number of tokens that have been minted and sold by crowdsale(s).
     * @return Amount of tokens minted through sale by crowdsale(s)
     */
    function soldSupply() public view returns (uint256);

    /**
     * @notice Returns the amount of tokens distributed through means other than selling them.
     * @return the amount of tokens distributed through means other than sale
     */
    function usedPrivateSupply() public view returns(uint256);

    /**
     * @notice Total number of tokens that have been minted.
     * @return total number of minted tokens
     */
    function totalSupply() public view returns (uint256);

    /**
     * @notice Maximum amount of tokens that can be minted.
     * @return maximum number of tokens that can be minted
     */
    function maximumSupply() public view returns (uint256);
}
