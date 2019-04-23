pragma solidity 0.4.24;


/**
 * @title ICrowdsale
 * @author Irresident Limited - www.irresident.io
 * @notice Interface defining crowdsale's API to be used by the token it is selling.
 */
contract ICrowdsale {
    /**
     * @notice Called by token to activate crowdsale for it's intended token.
     * @dev Throws if there are not enough tokens to satisfy reserved tokens requirements or if caller was not token.
     * @param _soldSupply amount of tokens sold by crowdsale(s)
     * @param _totalSupply amount of tokens in total minted
     * @return required crowdsale cap - amount of tokens allocated to selling by crowdsale
     */
    function activate(uint256 _soldSupply, uint256 _totalSupply) external returns(uint256);
    /**
     * @notice Called by token to deactivate crowdsale.
     * @dev Throws if caller is not contract or crowdsale owner
     */
    function deactivate() external;
}
