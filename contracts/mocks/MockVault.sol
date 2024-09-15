// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { IStakingRewards } from "../interfaces/IStakingRewards.sol";

/**
 * @title MockVault
 * @dev MockVault is a ERC4626 compliant vault for any ERC20 auto-compounded staking.
 * @dev The ERC4626 "Tokenized Vault Standard" is defined in https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 */
contract MockVault is ERC4626 {
    /* ========== STATE VARIABLES ========== */

    address public immutable coin;
    address public immutable stakingRewards;

    /* ========== EVENTS ========== */

    event HarvestRewards(uint256 amount);

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor to initialize the MockVault.
     * @param _coin ERC20 token contract address.
     * @param _stakingRewards Staking Rewards contract address.
     */
    constructor(
        IERC20 _coin,
        address _stakingRewards,
        string memory _name,
        string memory _symbol
    ) ERC4626(_coin) ERC20(_name, _symbol) {
        coin = address(_coin);
        stakingRewards = _stakingRewards;

        IERC20(coin).approve(stakingRewards, type(uint256).max);
    }

    /* ========== VIEWS ========== */

    /**
     * @dev See {IERC4626-totalAssets}.
     */
    function totalAssets() public view override returns (uint256) {
        uint256 totalDeposited = IStakingRewards(stakingRewards).balanceOf(address(this));
        uint256 totalUnclaimed = IStakingRewards(stakingRewards).earned(address(this));
        uint256 currentBalance = IERC20(coin).balanceOf(address(this));

        return (totalDeposited + totalUnclaimed + currentBalance);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Harvests Rewards annd restakes
     * the accumulated tokend back to Staking Rewards.
     */
    function harvestRewards() public {
        uint256 harvestAmount = IStakingRewards(stakingRewards).earned(address(this));

        if (harvestAmount > 0) {
            IStakingRewards(stakingRewards).getReward();
        }

        uint256 currentBalance = IERC20(coin).balanceOf(address(this));

        IStakingRewards(stakingRewards).stake(currentBalance);

        emit HarvestRewards(harvestAmount);
    }

    /**
     * @dev Hook called after a user deposits tokens to the vault.
     * Harvests token rewards.
     */
    function _afterDeposit() internal {
        harvestRewards();
    }

    /**
     * @dev Hook called before a user withdraws tokens from the vault.
     * Harvests token rewards and withdraws tokens.
     * @param assets The amount of tokens to be withdrawn.
     */
    function _beforeWithdraw(uint256 assets) internal {
        harvestRewards();
        IStakingRewards(stakingRewards).withdraw(assets);
    }

    /**
     * @dev See {ERC4626-_deposit}.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);
        _afterDeposit();
    }

    /**
     * @dev See {ERC4626-_withdraw}.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        _beforeWithdraw(assets);
        super._withdraw(caller, receiver, owner, assets, shares);
    }
}
