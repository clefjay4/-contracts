// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StableStakerArc is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdc;
    uint256 public constant REWARD_PERCENT = 5;

    struct StakeInfo {
        uint256 amount;
        uint256 reward;
    }

    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 amount, uint256 reward);
    event Withdrawn(address indexed user, uint256 total);
    event EmergencyWithdrawAll(address indexed owner, uint256 total);

    constructor(address _usdc) Ownable(msg.sender) {
        require(_usdc != address(0), "Invalid USDC address");
        usdc = IERC20(_usdc);
    }

    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount > 0");
        usdc.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 reward = (_amount * REWARD_PERCENT) / 100;
        StakeInfo storage s = stakes[msg.sender];
        s.amount += _amount;
        s.reward += reward;

        emit Staked(msg.sender, _amount, reward);
    }

    function withdraw() external nonReentrant {
        StakeInfo storage s = stakes[msg.sender];
        require(s.amount > 0, "Nothing to withdraw");

        uint256 total = s.amount + s.reward;
        s.amount = 0;
        s.reward = 0;

        usdc.safeTransfer(msg.sender, total);
        emit Withdrawn(msg.sender, total);
    }

    function emergencyWithdrawAll() external onlyOwner nonReentrant {
        uint256 balance = usdc.balanceOf(address(this));
        require(balance > 0, "No balance");
        usdc.safeTransfer(owner(), balance);
        emit EmergencyWithdrawAll(owner(), balance);
    }

    function getMyStake() external view returns (uint256 amount, uint256 reward) {
        StakeInfo memory s = stakes[msg.sender];
        return (s.amount, s.reward);
    }

    receive() external payable { revert("ETH not accepted"); }
    fallback() external payable { revert("ETH not accepted"); }
}
