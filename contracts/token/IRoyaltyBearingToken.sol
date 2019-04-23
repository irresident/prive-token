pragma solidity 0.4.24;


/**
 * @title IRoyaltyBearingToken
 * @author Irresident Limited - www.irresident.io
 * @notice Interface defining token's API to be used by royalty mechanism to  to keep track of claimed and available
 *         (i.e. unclaimed) royalties.
 */
contract IRoyaltyBearingToken {

    /**
     * @notice Returns number of royalty distribution rounds for which interest claim data is available.
     * @return number of royalty distribution rounds with available interest claim data; can be 0 to
     *         MAX_ROYALTY_DISTRIBUTION_ROUNDS
     */
    function royaltyDistributionRounds() public view returns(uint8);

    /**
     * @notice Returns id of the earliest royalty distribution round id for which interest claims are stored.
     * @notice Royalty distribution rounds older than this one are considered expired and their interest claim data is
     *         discarded.
     * @return id of the earliest stored royalty distribution round or 0 if there are no rounds
     */
    function earliestRoyaltyDistributionRound() public view returns(uint256);

    /**
     * @notice Returns id of the latest royalty distribution round id for which interest claims are stored.
     * @return id of the latest stored royalty distribution round or 0 if there are no rounds
     */
    function latestRoyaltyDistributionRound() public view returns(uint256);

    /**
     * @dev Starts a new royalty distribution round.
     * @dev Throws if called by anything other than royalty mechanism.
     * @return id of the new round
     */
    function startNewRoyaltyDistributionRound() external returns(uint256);

    /**
     * @notice Returns sum of royalties claimed across all holder's for a given round.
     * @notice It will throw if _round is 0.
     * @param _round id of the royalty distribution round
     * @return sum of royalty interest that has been claimed across all holders or 0 if none
     */
    function getTotalClaimedRoyaltiesForRound(uint256 _round) public view
    returns(uint256 _claimedInterest, bool _hasRecord);

    /**
     * @notice Returns sum total of all claimed royalty interest across all holders for all tracked royalty
     *         distribution rounds: from earliestRoyaltyDistributionRound to latestRoyaltyDistributionRound.
     * @return _count count of tracked royalty distribution rounds (0 to MAX_ROYALTY_DISTRIBUTION_ROUNDS)
     * @return _claimedInterest total claimed royalty interest for last _count royalty distribution rounds
     *         across all holders
     * @return _round ids for _count royalty distribution rounds that _claimedInterest is for
     */
    function getTotalClaimedRoyalties() external view
    returns(uint8 _count, uint256[3] _claimedInterest, uint256[3] _round);

    /**
     * @notice Returns holder's claimed royalty interest for given royalty distribution round id.
     * @notice It will throw if _round is 0.
     * @param _holder address of the token holder
     * @param _round id of the royalty distribution round
     * @return _claimedInterest amount of royalty interest that has been claimed in given round or 0 if none
     * @return _hasRecord true if there is a record for royalty distribution round or false otherwise
     */
    function getClaimedRoyaltiesForRound(address _holder, uint256 _round) public view
    returns(uint256 _claimedInterest, bool _hasRecord);

    /**
     * @notice Returns holder's claimed royalty interest for all tracked royalty distribution rounds: from
     *         earliestRoyaltyDistributionRound to latestRoyaltyDistributionRound.
     * @return _count count of tracked royalty distribution rounds (0 to MAX_ROYALTY_DISTRIBUTION_ROUNDS)
     * @return _claimedInterest claimed royalty interest for last _count royalty distribution rounds
     * @return _round ids for _count royalty distribution rounds that _claimedInterest is for
     */
    function getClaimedRoyalties(address _holder) external view
    returns(uint8 _count, uint256[3] _claimedInterest, uint256[3] _round);

    /**
     * @notice Returns any available royalty interest for holder and royalty distribution round id.
     * @notice It will throw if _round is 0.
     * @param _holder address of the token holder
     * @param _round id of the royalty distribution round
     * @return _availableInterest amount of royalty interest that is available to be claimed or 0 if none
     * @return _hasRecord true if there is a record for royalty distribution round or false otherwise
     */
    function getAvailableRoyaltiesForRound(address _holder, uint256 _round) public view
    returns(uint256 _availableInterest, bool _hasRecord);

    /**
     * @notice Returns available royalty interest for holder across all tracked royalty distribution rounds: from
     *         earliestRoyaltyDistributionRound to latestRoyaltyDistributionRound.
     * @return _count count of tracked royalty distribution rounds (0 to MAX_ROYALTY_DISTRIBUTION_ROUNDS)
     * @return _availableInterest royalty interest for last _count royalty distribution rounds that is available for
     *         claiming
     * @return _round ids for _count royalty distribution rounds that _unclaimedInterest is claimed for
     */
    function getAvailableRoyalties(address _holder) external view
    returns(uint8 _count, uint256[3] _availableInterest, uint256[3] _round);

    /**
     * @notice Checks if token holder can claim their royalties.
     * @param _holder address of the token holder
     * @return true if token holder has accepted the copyright agreement, false otherwise
     */
    function canClaimRoyalties(address _holder) public view returns(bool);

    /**
     * @dev Claims and returns holder's unclaimed royalty interest for all tracked royalty distribution rounds: from
     *      earliestRoyaltyDistributionRound to latestRoyaltyDistributionRound.
     * @dev Throws if called by anything other than royalty mechanism.
     * @dev Throws if holder is not vested i.e. has not accepted license agreement
     * @dev Throws if there are not active rounds i.e. latestRoyaltyDistributionRound is 0.
     * @param _holder address of the token holder for whom royalty interest is claimed
     * @return _count count of tracked royalty distribution rounds (0 to MAX_ROYALTY_DISTRIBUTION_ROUNDS)
     * @return _newInterest royalty interest for last _count royalty distribution rounds that have just been claimed
     */
    function accountForRoyaltyClaim(address _holder) external returns(uint8 _count, uint256[3] _newInterest);

}
