// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IYieldForGood } from "./interfaces/IYieldForGood.sol";
import { IYieldForGoodSoulBound } from "./interfaces/IYieldForGoodSoulBound.sol";

/**
 * @title YieldForGood
 * @dev Yield For Good provides a way for users to delegate their yield to charitable causes.
 */
contract YieldForGood is IYieldForGood, Ownable {
    /* ========== STATE VARIABLES ========== */

    mapping(uint256 => Pool) public pools;
    mapping(address => bool) public supportedYieldSources;

    uint256 public lastPoolId;
    address public yfgSoulbound;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor to initialize the YieldForGood contract.
     */
    constructor() Ownable(msg.sender) {}

    /* ========== VIEWS ========== */

    /**
     * @dev Returns an estimate of the accrued yield for a specific pool.
     * @param poolId The id of the pool to enter.
     * @return accruedYield The accrued yield for the chosen pool.
     * @return underlyingAsset The undedrlying asset of the pool.
     */
    function getAccruedYieldForPool(
        uint256 poolId
    ) external view returns (uint256 accruedYield, address underlyingAsset) {
        Pool storage pool = pools[poolId];

        // Check if pool exists
        if (poolId > lastPoolId) revert PoolDoesNotExist();

        // Convert total shares to underlying assset, so we can calculate the yield amount by deducting the principal
        uint256 sharesToAsset = IERC4626(pool.yieldSource).previewRedeem(pool.totalSharesDelegated);

        // Calclulate the yield to claim
        (sharesToAsset > pool.totalAssetPrincipal)
            ? accruedYield = sharesToAsset - pool.totalAssetPrincipal
            : accruedYield = 0;

        // Get the underlying asset
        underlyingAsset = pool.asset;
    }

    /**
     * @dev Returns the user's principal amount staked.
     * @param poolId The id of the pool where the user has staked.
     * @param user The address of the user.
     * @return userPrincipal The user's principal amount staked.
     */
    function getUserPrincipal(uint256 poolId, address user) external view returns (uint256 userPrincipal) {
        userPrincipal = pools[poolId].userPrincipal[user];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Enters the YFG by depositing amount of tokens.
     * @param poolId The id of the pool to enter.
     * @param amount The amount of tokens to deposit.
     */
    function enter(uint256 poolId, uint256 amount) external {
        Pool storage pool = pools[poolId];

        if (poolId > lastPoolId) revert PoolDoesNotExist();

        // Check if it's first time depositor
        if (pool.userPrincipal[msg.sender] == 0 && !pool.userParticipated[msg.sender]) {
            // Mint Soulbound to depositor
            IYieldForGoodSoulBound(yfgSoulbound).mint(msg.sender);

            // Mark that user has participated in the pool
            pool.userParticipated[msg.sender] = true;
        }

        // Increment total participants
        if (pool.userPrincipal[msg.sender] == 0) {
            ++pool.totalParticipants;
        }

        // Transfer the underlying asset to the YFG Contract
        IERC20(pool.asset).transferFrom(msg.sender, address(this), amount);

        // Deposit the transferred asset to the underlying ERC-4626 yield source
        uint256 shares = IERC4626(pool.yieldSource).deposit(amount, address(this));

        // Increment the total shares generating yield for the pool
        pool.totalSharesDelegated += shares;

        // Increment the total asset principal amount
        pool.totalAssetPrincipal += amount;

        // Increment the asset principal amount for the user
        pool.userPrincipal[msg.sender] += amount;

        emit PoolEntered(poolId, pool.asset, amount);
    }

    function exit(uint256 poolId, uint256 amount) external {
        Pool storage pool = pools[poolId];

        if (poolId > lastPoolId) revert PoolDoesNotExist();
        if (amount > pool.userPrincipal[msg.sender]) revert NotEnoughFundsToWithdraw();

        // Withdraw the requested asset to the YFG contract
        uint256 shares = IERC4626(pool.yieldSource).withdraw(amount, address(this), address(this));

        // Decrement the total shares generating yield for the pool
        pool.totalSharesDelegated -= shares;

        // Decrement the total asset principal amount
        pool.totalAssetPrincipal -= amount;

        // Decrement the asset principal amount
        pool.userPrincipal[msg.sender] -= amount;

        // Decrement total participants
        if (pool.userPrincipal[msg.sender] == 0) {
            --pool.totalParticipants;
        }

        // Transfer the underlying asset to the depositor
        IERC20(pool.asset).transfer(msg.sender, amount);

        emit PoolExited(poolId, pool.asset, amount);
    }

    /**
     * @dev Creates an YieldForGoodPool to collect aggregated yield.
     * @param yieldSource The address of the yield source.
     */
    function createPool(
        address yieldSource,
        string memory title,
        string memory description,
        string memory imageURI
    ) external {
        if (!supportedYieldSources[yieldSource]) revert YieldSourceNotSupported();

        ++lastPoolId;

        uint256 poolId = lastPoolId;
        address underlyingAsset = IERC4626(yieldSource).asset();

        pools[poolId].poolOwner = msg.sender;
        pools[poolId].yieldSource = yieldSource;
        pools[poolId].asset = underlyingAsset;
        pools[poolId].creationDate = block.timestamp;

        pools[poolId].title = title;
        pools[poolId].description = description;
        pools[poolId].imageURI = imageURI;

        IERC20(underlyingAsset).approve(yieldSource, type(uint256).max);

        emit PoolCreated(lastPoolId, yieldSource, underlyingAsset, msg.sender);
    }

    /**
     * @dev Claims the accrued yield from a specific pool.
     * @param poolId The id of the pool to enter.
     * @return yieldForClaim The claimed yield.
     */
    function claimYield(uint256 poolId) external returns (uint256 yieldForClaim) {
        Pool storage pool = pools[poolId];

        // Check if pool exists
        if (poolId > lastPoolId) revert PoolDoesNotExist();

        // Check if caller is owner of the pool
        if (msg.sender != pool.poolOwner) revert NotOwnerOfPool();

        // Convert total shares to underlying assset, so we can calculate the yield amount by deducting the principal
        uint256 sharesToAsset = IERC4626(pool.yieldSource).previewRedeem(pool.totalSharesDelegated);

        // Calclulate the yield to claim
        (sharesToAsset > pool.totalAssetPrincipal)
            ? yieldForClaim = sharesToAsset - pool.totalAssetPrincipal
            : yieldForClaim = 0;

        // Withdraw the requested asset to the YFG contract
        IERC4626(pool.yieldSource).withdraw(yieldForClaim, address(this), address(this));

        // Reacalulate the new share amount in relation to the principal
        pool.totalSharesDelegated = IERC4626(pool.yieldSource).previewWithdraw(pool.totalAssetPrincipal);

        // Transfer the accrued yield to the owner of the pool
        IERC20(pool.asset).transfer(msg.sender, yieldForClaim);

        emit YieldClaimed(poolId, yieldForClaim, pool.asset, pool.yieldSource, pool.poolOwner);
    }

    /**
     * @dev Toggle yield source support. Should be ERC-4626 vault.
     * @param yieldSource The address of the yield source.
     * @param isSupported Is the yield source supported.
     */
    function updateSupportedYieldSource(address yieldSource, bool isSupported) external onlyOwner {
        if (yieldSource == address(0)) revert AddressZero();

        supportedYieldSources[yieldSource] = isSupported;

        emit UpdateSupportedYieldSource(yieldSource, isSupported);
    }

    /**
     * @dev Sets the YFG Soulbound contract.
     * @param _yfgSoulbound The address of the YGF Soulbound.
     */
    function setYFGSoulbound(address _yfgSoulbound) external onlyOwner {
        yfgSoulbound = _yfgSoulbound;
    }
}
