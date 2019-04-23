pragma solidity 0.4.24;

import "./LegalProse.sol";


/**
 * @title Smart contract with Prive copyright agreement legal prose.
 */
contract PriveLegalProse is LegalProse {
    // Prive copyright agreement legal prose
    // solhint-disable-next-line max-line-length
    string public copyrightAgreement_ = "Privé Joint Copyright Ownership Agreement\n\nArticle 1\n\nThe Privé token represents fractional undivided interest in the copyright of the Privé software platform and all derivative works, in proportion to all Privé tokens. This interest becomes vested when a Privé token holder accepts the terms of the Joint Copyright Ownership Agreement as laid down in this text.\n\nArticle 2\n\nThe terms of the Joint Copyright Ownership Agreement are accepted by a Privé token holder when the Privé token holder invokes Privé token’s ‘acceptAgreement’ function, thus confirming that the Privé token holder has read the terms, understands the terms, and accepts the terms of the Agreement. The record of such a function call on the Ethereum blockchain network shall be taken as evidence of the acceptance of this agreement.\n\nArticle 3\n\nThe Privé software platform refers to software developed under the name “Privé”; authored by Damir Petkovic and Luka Arvaj (“Authors”) and produced under the management of said Authors; that employs a licensing and royalty-distribution blockchain-based smart-contract mechanism; provided as is and as ongoing work. Any other software developed by the Authors, or developed under the name “Privé”, or developed without employing the said licensing and royalty-distribution blockchain-based smart-contract mechanism, shall not be deemed Privé software platform.\n\nArticle 4\n\nThe rights and obligations of Privé token holders with vested fractional undivided interest in the copyright of the Privé software platform and all derivative works (“vested Privé token holders”), arising from their interest in the copyright of the Privé software platform and all derivative works, and from acceptance of this agreement, shall be governed by the laws of the U.S. state of Delaware, excluding its conflict of laws provisions. Any dispute arising out of or in connection with such rights and obligations shall be referred to and finally resolved by arbitration administered by the Hong Kong International Arbitration Centre under the Hong Kong International Arbitration Centre Administered Arbitration rules in force when the Notice of Arbitration is submitted. The seat, or legal place, of arbitration shall be Hong Kong. The number of arbitrators shall be three. The arbitration proceedings shall be conducted in English. The governing law shall be the substantive law of the U.S. state of Delaware, excluding its conflict of laws provisions.\n\nArticle 5\n\nFractional undivided interest in the copyright of the Privé software platform and all derivative works is assignable only by means of Privé token transfer on the Ethereum blockchain network, contingent upon acceptance of the terms of the Joint Copyright Ownership Agreement by the acquirer of Privé tokens. Record of such transfer and acceptance on the Ethereum blockchain network shall be deemed an assignment made in writing.\n\nArticle 6\n\nNo vested Privé token holder shall have any obligation to obtain any approval of other vested Privé token holders to exercise their rights granted under copyright law, including, but not limited to: the right to produce copies of the software, and the right to create derivative works and license the software to end users of the Privé software platform and all derivative works. Each vested Privé token holder hereby waives any right he or she may have under the applicable laws of any jurisdiction to require such approval.\n\nArticle 7\n\nThe duty to account for profits to all vested Privé token holders shall be deemed to be fulfilled by a smart contract mechanism pertaining to the Privé software platform. Each vested Privé token holder shall collect his/her share of royalties within a time period not longer than three years (expiration period) from the moment in which the smart contract mechanism makes such royalties available for collection by the vested Privé token holders. In the case in which a vested Privé token holder does not collect his/her share of royalties within the specified timeframe, and in order to avoid the permanent loss of accrued royalties associated with any lost Privé tokens, the smart contract mechanism shall reallocate such uncollected shares of royalties and make them available for collection to all vested Privé token holders, in proportion to their token holdings at that given moment. A new three-year expiration period will then be applied to the collection of said royalties. Such a mechanism shall be implemented in all derivative works based on the Privé software platform.\n\nArticle 8\n\nAll works deriving from the Privé software platform shall be owned by vested Privé token holders. Any author of derivative works hereby assigns to vested Privé token holders all rights, titles, and interests in the derivative work. The Privé token shall represent fractional undivided interest in the copyright of such work, in the same way it represents fractional undivided interest in the copyright of the original Privé software platform.\n\nArticle 9\n\nThe only licenses vested Privé token holders may grant in regard to the Privé software platform and all derived works are those licenses that adhere to the terms and conditions drafted by the Authors, pertaining to the Privé software platform.\n\nArticle 10\n\nThe right of vested Privé token holders to use the Privé software platform and all derivative works as end users shall be subject to the terms and conditions of the end-user license as drafted by the Authors, pertaining to the Privé software platform.\n\nArticle 11\n\nNothing contended herein shall be deemed to create an agency, joint venture, franchise, or partnership relation between vested Privé token holders or between vested Privé token holders and the Authors, and no vested Privé token holder shall so hold itself.\n";

    /**
     * @notice Returns Prive copyright agreement legal prose
     * @return string containing Prive copyright agreement legal prose
     */
    function copyrightAgreement() public view returns(string) {
        return copyrightAgreement_;
    }
}
