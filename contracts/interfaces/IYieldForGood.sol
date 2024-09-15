// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IYieldForGood {
    /* ========== EVENTS ========== */

    event YieldClaimed(uint256 poolId, uint256 amount, address underlyingAsset, address yieldSource, address receiver);
    event UpdateSupportedYieldSource(address yieldSource, bool isSupported);
    event PoolCreated(uint256 poolId, address yieldSource, address underlyingAsset, address poolOwner);
    event PoolEntered(uint256 poolId, address underlyingAsset, uint256 amount);
    event PoolExited(uint256 poolId, address underlyingAsset, uint256 amount);

    /* ========== CUSTOM ERRORS ========== */

    error NotOwnerOfPool();
    error PoolDoesNotExist();
    error YieldSourceNotSupported();
    error NotEnoughFundsToWithdraw();
    error AddressZero();

    struct Pool {
        string title;
        string description;
        string imageURI;
        address poolOwner;
        address yieldSource;
        address asset;
        uint256 totalSharesDelegated;
        uint256 totalAssetPrincipal;
        uint256 creationDate;
        uint256 totalParticipants;
        mapping(address => uint256) userPrincipal;
        mapping(address => bool) userParticipated;
    }

    function enter(uint256 poolId, uint256 amount) external;

    function exit(uint256 poolId, uint256 amount) external;

    function createPool(
        address yieldSource,
        string memory title,
        string memory description,
        string memory imageURI
    ) external;

    function claimYield(uint256 poolId) external returns (uint256 yieldForClaim);

    function getAccruedYieldForPool(
        uint256 poolId
    ) external view returns (uint256 accruedYield, address underlyingAsset);

    function getUserPrincipal(uint256 poolId, address user) external view returns (uint256 userPrincipal);
}
