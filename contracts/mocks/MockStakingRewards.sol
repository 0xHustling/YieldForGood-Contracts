// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * \
 * Custom implementation of the StakingRewards contract by Synthetix.
 *
 * https://docs.synthetix.io/contracts/source/contracts/stakingrewards
 * https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol
 * /*****************************************************************************
 */

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IStakingRewards.sol";

/**
 * @title Staking Rewards
 * @dev A contract for staking and earning rewards with any ERC20 token.
 */
contract MockStakingRewards is IStakingRewards, ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    address public rewardsToken;
    address public stakingToken;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public lockPeriod;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public latestStakeCheckpoint;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Initializes the StakingRewards contract.
     * @param _rewardsToken The address of the token used for rewards.
     * @param _stakingToken The address of the token being staked.
     * @param _rewardsDuration The duration of the rewards period.
     * @param _lockPeriod The lock period when staking tokens.
     */
    constructor(
        address _rewardsToken,
        address _stakingToken,
        uint256 _rewardsDuration,
        uint256 _lockPeriod
    ) Ownable(msg.sender) {
        rewardsToken = _rewardsToken;
        stakingToken = _stakingToken;
        rewardsDuration = _rewardsDuration;
        lockPeriod = _lockPeriod;
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Returns the balance of the specified account.
     * @param account The address to check the balance for.
     * @return The balance of the account.
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Returns the last time when rewards were applicable.
     * @return The last time rewards were applicable.
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /**
     * @dev Returns the rewards per staked token.
     * @return The reward tokens earned per staked token.
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored + (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalSupply);
    }

    /**
     * @dev Returns the total rewards earned by the specified account.
     * @param account The address to check the rewards for.
     * @return The total rewards earned by the account.
     */
    function earned(address account) public view returns (uint256) {
        return ((balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    /**
     * @dev Returns the total reward amount for the rewards duration.
     * @return The total reward amount for the rewards duration.
     */
    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Stakes the specified amount of tokens.
     * @param amount The amount of tokens to stake.
     */
    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        totalSupply = totalSupply + amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        latestStakeCheckpoint[msg.sender] = block.timestamp;
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Withdraws the specified amount of tokens.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        if (periodFinish >= block.timestamp) {
            require(latestStakeCheckpoint[msg.sender] + lockPeriod <= block.timestamp, "Tokens are currently locked");
        }
        totalSupply = totalSupply - amount;
        balances[msg.sender] = balances[msg.sender] - amount;
        IERC20(stakingToken).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Claims the available rewards for the caller.
     */
    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IERC20(rewardsToken).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /**
     * @dev Withdraws the staked tokens and claims the available rewards for the caller.
     */
    function exit() external {
        withdraw(balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Notifies the contract about the reward amount to be distributed.
     * @param reward The amount of rewards to be distributed.
     */
    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = IERC20(rewardsToken).balanceOf(address(this));
        require(rewardRate <= balance / rewardsDuration, "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + (rewardsDuration);
        emit RewardAdded(reward);
    }

    /**
     * @dev Recovers ERC20 tokens accidentally sent to the contract.
     * @param tokenAddress The address of the ERC20 token to recover.
     * @param tokenAmount The amount of tokens to recover.
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @dev Withdraws the staking rewards from the contract.
     * @param destinationAddress The address to which the staking rewards will be transferred.
     * @param pendingRewards Amount of pending rewards to be subtracted from the total and remain in the contract.
     */
    function withdrawStakingRewards(address destinationAddress, uint256 pendingRewards) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before withdrawing the staking rewards"
        );
        // Remaining rewards are calclulated by substracting the totalSupply + pendingRewards from the total balance
        uint256 tokenAmount = IERC20(stakingToken).balanceOf(address(this)) - totalSupply - pendingRewards;
        IERC20(stakingToken).safeTransfer(destinationAddress, tokenAmount);
        emit WithdrawStakingRewards(destinationAddress, tokenAmount);
    }

    /**
     * @dev Sets the rewards duration for the next rewards period.
     * @param _rewardsDuration The new rewards duration.
     */
    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /**
     * @dev Pauses the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /* ========== MODIFIERS ========== */

    /**
     * @dev Updates the reward variables for the specified account.
     * @param account The account to update the reward variables for.
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    event WithdrawStakingRewards(address receiver, uint256 amount);
}
