pragma solidity 0.4.24;

import "./LegalProse.sol";


/**
 * @title Smart contract with reference to Prive copyright agreement legal prose and record of user addresses who
 * accepted the agreement.
 */
contract PriveCopyright {

    // Contract providing copyright agreement legal prose for Prive
    LegalProse public legalProse;

    /**
     * @notice Event for logging acceptance of agreement.
     * @param acceptedBy address of entity that accepted the agreement
     */
    event CopyrightAgreementAccepted(address indexed acceptedBy);

    // map of addresses that accepted the agreement with block.timestamp of when the agreement was accepted
    mapping(address => uint256) public acceptedAgreements;


    constructor(LegalProse _legalProse) public {
        legalProse = _legalProse;
    }

    /**
     * @notice Returns Prive copyright agreement legal prose
     * @return string containing Prive copyright agreement legal prose
     */
    function copyrightAgreement() public view returns(string) {
        return legalProse.copyrightAgreement();
    }

    /**
     * @notice Call to accept the agreement. NOTE: the address from which the function is called will be used to accept
     *         the agreement.
     * @dev Only emits event if the address has not previously accepted the agreement.
     */
    function acceptAgreement() external {
        address acceptedBy = msg.sender;
        if (acceptedAgreements[acceptedBy] == 0) {
            acceptedAgreements[acceptedBy] = uint256(now);
            emit CopyrightAgreementAccepted(acceptedBy);
        }
    }
}
