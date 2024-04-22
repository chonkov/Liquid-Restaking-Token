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

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = block.timestamp;

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    function deposit(uint256 amount, address receiver) external updateReward(msg.sender) {
        liquidStakingToken.safeTransferFrom(msg.sender, address(this), amount);
        liquidStakingToken.safeIncreaseAllowance(address(strategyManager), amount);
        uint256 shares = strategyManager.depositIntoStrategy(strategy, liquidStakingToken, amount);

        balanceOf[msg.sender] += amount;
        totalSupply += amount;

        liquidRestakingToken.mint(receiver, shares);

        emit Deposit(msg.sender, receiver, amount);
    }

    function delegateTo(
        address operator,
        IDelegationManager.SignatureWithExpiry calldata approverSignatureAndExpiry,
        bytes32 approverSalt
    ) external onlyRole(ADMIN_ROLE) {
        delegationManager.delegateTo(operator, approverSignatureAndExpiry, approverSalt);
    }

    function undelegateFrom() external onlyRole(ADMIN_ROLE) {
        delegationManager.undelegate(address(this));
    }

    function queueWithdrawals(IDelegationManager.QueuedWithdrawalParams[] calldata queuedWithdrawalParams)
        external
        onlyRole(ADMIN_ROLE)
    {
        delegationManager.queueWithdrawals(queuedWithdrawalParams);
    }

    function completeQueuedWithdrawal(
        IDelegationManager.Withdrawal calldata withdrawal,
        IERC20[] calldata tokens,
        uint256 middlewareTimesIndex,
        bool receiveAsTokens
    ) external onlyRole(ADMIN_ROLE) {
        delegationManager.completeQueuedWithdrawal(withdrawal, tokens, middlewareTimesIndex, receiveAsTokens);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (REWARD_RATE * (block.timestamp - updatedAt) * 1e18) / totalSupply;
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account] * (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) + rewards[_account];
    }

    function getRewards() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.mint(msg.sender, reward);
        }
    }
}
