pragma solidity 0.4.24;


/**
 * @title Interface to smart contract providing copyright agreement legal prose.
 */
contract LegalProse {
    /**
     * @notice Returns copyright agreement legal prose
     * @return string containing copyright agreement legal prose
     */
    function copyrightAgreement() public view returns(string);
}
