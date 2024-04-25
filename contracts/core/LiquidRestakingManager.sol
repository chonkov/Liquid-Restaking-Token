// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {ILiquidRestakingToken} from "./interfaces/ILiquidRestakingToken.sol";
import {ILiquidRestakingManager} from "./interfaces/ILiquidRestakingManager.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {IStrategyManager} from "./interfaces/IStrategyManager.sol";
import {IDelegationManager} from "./interfaces/IDelegationManager.sol";
import {LiquidRestakingToken} from "./LiquidRestakingToken.sol";

/**
 * @author Georgi Chonkov
 * @notice Main contract acting as an entry point. Users can deposit LSTs in exchange for LRTs and additional yield
 */
contract LiquidRestakingManager is ILiquidRestakingManager, AccessControl {
    using SafeERC20 for IERC20;

    // keccak256("ADMIN_ROLE");
    bytes32 public constant ADMIN_ROLE = 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;
    uint256 public constant REWARD_RATE = 1_000;

    ILiquidRestakingToken public immutable liquidRestakingToken;
    IERC20 public immutable liquidStakingToken;
    IStrategy public immutable strategy;

    IStrategyManager public immutable strategyManager;
    IDelegationManager public immutable delegationManager;
    ILiquidRestakingToken public immutable rewardsToken;

    uint256 public updatedAt;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    /**
     * @param admin_ `Safe` multi-signature wallet
     * @param name_ Name of LRT (Liquid Restaking Token)
     * @param symbol_ Symbol of LRT
     * @param rewardTokenName_ Name of reward token
     * @param rewardTokenSymbol_ Symbol of reward token
     * @param liquidStakingToken_ LST used for deposits by users. Deposited into EigenLayer.
     * @param strategy_ Whitelisted strategy by EigenLayer
     * @param strategyManager_ EigenLayer's Strategy manager
     * @param delegationManager_ EigenLayer's Delegation manager
     */
    constructor(
        address admin_,
        string memory name_,
        string memory symbol_,
        string memory rewardTokenName_,
        string memory rewardTokenSymbol_,
        IERC20 liquidStakingToken_,
        IStrategy strategy_,
        IStrategyManager strategyManager_,
        IDelegationManager delegationManager_
    ) {
        _grantRole(ADMIN_ROLE, admin_);
        if (!hasRole(ADMIN_ROLE, admin_)) revert();

        liquidRestakingToken = new LiquidRestakingToken(name_, symbol_);
        liquidStakingToken = liquidStakingToken_;
        strategy = strategy_;
        strategyManager = strategyManager_;
        delegationManager = delegationManager_;

        rewardsToken = new LiquidRestakingToken(rewardTokenName_, rewardTokenSymbol_);
    }

    /**
     * @notice Updates `userRewardPerTokenPaid` & `rewardPerTokenStored` storage variables
     * @param account User that makes a call
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = block.timestamp;

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /**
     * @notice Main function used by user to deposit their LSTs
     * @param amount The amount of tokens to deposit
     * @param receiver The address that will receive LRT tokens and can later claim rewards
     * @dev It transfers all tokens to the `Strategy Manager` and mints the corresponding `shares`
     */
    function deposit(uint256 amount, address receiver) external updateReward(msg.sender) {
        liquidStakingToken.safeTransferFrom(msg.sender, address(this), amount);
        liquidStakingToken.safeIncreaseAllowance(address(strategyManager), amount);
        uint256 shares = strategyManager.depositIntoStrategy(strategy, liquidStakingToken, amount);

        balanceOf[msg.sender] += amount;
        totalSupply += amount;

        liquidRestakingToken.mint(receiver, shares);

        emit Deposit(msg.sender, receiver, amount);
    }

    /**
     * @notice Delegates to an operator. Only `admin` can call this function
     * @param operator Operator to delegate to
     * @param approverSignatureAndExpiry Signature, used only if the operator requires it
     * @param approverSalt Random value
     */
    function delegateTo(
        address operator,
        IDelegationManager.SignatureWithExpiry calldata approverSignatureAndExpiry,
        bytes32 approverSalt
    ) external onlyRole(ADMIN_ROLE) {
        delegationManager.delegateTo(operator, approverSignatureAndExpiry, approverSalt);

        emit DelegateTo(operator);
    }

    /**
     * @notice Undelegates from an operator. Only `admin` can call this function
     */
    function undelegateFrom() external onlyRole(ADMIN_ROLE) {
        delegationManager.undelegate(address(this));

        emit UndelegateFrom();
    }

    /**
     * @notice Queues a withdrawal. Only `admin` can call this function
     * @param queuedWithdrawalParams Operator to delegate to
     */
    function queueWithdrawals(IDelegationManager.QueuedWithdrawalParams[] calldata queuedWithdrawalParams)
        external
        onlyRole(ADMIN_ROLE)
    {
        delegationManager.queueWithdrawals(queuedWithdrawalParams);

        emit QueueWithdrawal(queuedWithdrawalParams);
    }

    /**
     * @notice Completes a withdrawal after a certain period has passed. Only `admin` can call this function
     * @param withdrawal The withdraw to complete
     * @param tokens Tokens to receive
     * @param middlewareTimesIndex Index which is currently not required (After the slasher is added it should be specified)
     * @param receiveAsTokens Whether to receive tokens or shares
     */
    function completeQueuedWithdrawal(
        IDelegationManager.Withdrawal calldata withdrawal,
        IERC20[] calldata tokens,
        uint256 middlewareTimesIndex,
        bool receiveAsTokens
    ) external onlyRole(ADMIN_ROLE) {
        delegationManager.completeQueuedWithdrawal(withdrawal, tokens, middlewareTimesIndex, receiveAsTokens);

        emit CompleteQueuedWithdrawal(withdrawal, tokens, middlewareTimesIndex, receiveAsTokens);
    }

    /**
     * @notice Calculates the value stored in `rewardPerTokenStored` variable
     * @dev It is used the same way as in Synthetix's `Staking Rewards` contract
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (REWARD_RATE * (block.timestamp - updatedAt) * 1e18) / totalSupply;
    }

    /**
     * @notice Returns earned rewards
     * @param account Earned rewards by this account
     */
    function earned(address account) public view returns (uint256) {
        return ((balanceOf[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    /**
     * @notice Allows caller to claim their rewards
     */
    function claimRewards() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.mint(msg.sender, reward);
        }
    }
}
