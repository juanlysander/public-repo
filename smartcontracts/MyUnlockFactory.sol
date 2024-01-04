// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@unlock-protocol/contracts/dist/Unlock/IUnlockV12.sol";
import "@unlock-protocol/contracts/dist/PublicLock/IPublicLockV13.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyUnlockFactory Contract
 * @author juanlysander
 * @dev This contract serves as a factory for creating new locks using the Unlock protocol. It provides
 *      functionalities for setting default metadata, fee structures, and lock symbols. This simplifies
 *      the process of creating locks that are consistent with the platform's style, enabling easier
 *      identification and filtering. For more details on the Unlock protocol, visit: https://unlock-protocol.com/
 */

contract MyUnlockFactory is Ownable(msg.sender) {
    address public unlockAddress;
    address public platformAddress;
    uint16 public bps = 375;
    string public constant LOCK_SYMBOL = "GALA";

    /**
     * @dev
     * @param _unlockAddress existing unlock address from same network https://docs.unlock-protocol.com/core-protocol/unlock/networks
     */
    constructor(address _unlockAddress) {
        unlockAddress = _unlockAddress;
        platformAddress = msg.sender;
    }

    /**
     * @dev Transfers the ownership of the contract to a new address. Can only be called by the current owner.
     * @notice This function will revert if the new owner is the zero address.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public override onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Sets a new platform address. Only callable by the contract owner.
     * @param _platformAddress The address to set as the new platform address.
     */
    function setPlatformAddress(address _platformAddress) public onlyOwner {
        platformAddress = _platformAddress;
    }

    /**
     * @dev Sets the basis points (bps). Only callable by the contract owner.
     * @param _bps The basis points to be set.
     */
    function setBps(uint16 _bps) public onlyOwner {
        bps = _bps;
    }

    /**
     * @dev Sets the basis points (bps). Only callable by the contract owner.
     * @param _userAddress The basis points to be set.
     * @param _expirationDuration The duration of subscription.
     * @param _tokenAddress The address of token / native token.
     * @param _keyPrice Price of one key.
     * @param _maxNumberOfKeys Maximum of active subscription.
     * @param _lockName Name of the lock.
     * @param _baseLockURI Metadata Uri.
     */
    function deployNewLock(
        address _userAddress,
        uint256 _expirationDuration,
        address _tokenAddress,
        uint256 _keyPrice,
        uint256 _maxNumberOfKeys,
        string memory _lockName,
        string memory _baseLockURI
    ) external returns (address) {
        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,uint256,address,uint256,uint256,string)",
            _userAddress,
            _expirationDuration,
            _tokenAddress,
            _keyPrice,
            _maxNumberOfKeys,
            _lockName
        );

        IUnlockV12 unlock = IUnlockV12(unlockAddress);

        address newLockAddress = unlock.createUpgradeableLockAtVersion(initData, 12);
        IPublicLockV13(newLockAddress).updateRefundPenalty(0, 10000);
        IPublicLockV13(newLockAddress).addLockManager(_userAddress);
        IPublicLockV13(newLockAddress).setReferrerFee(platformAddress, bps);
        IPublicLockV13(newLockAddress).setLockMetadata(_lockName, LOCK_SYMBOL, _baseLockURI);

        // Renouncing yourself from LockManager role (optional)
        IPublicLockV13(newLockAddress).renounceLockManager();
        return newLockAddress;
    }
}
