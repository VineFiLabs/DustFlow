// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IDustPool} from "../interfaces/IDustPool.sol";
import "../libraries/DustFlowLibrary.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @author  .One of the members of VineLabs, 0xlive
 * @title   .DustPool
 * @dev     .DUST staking reward pool
 * @notice  .During the staking period, DUST will be locked in DUSTPool and can be deposited or withdrawn at any time
 */
contract DustPool is IDustPool, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public owner;
    address public manager;
    address public dust;
    address public rewardToken;

    uint256 public reserve0;
    uint256 public reserve1;

    uint256 public totalPledge;
    uint256 public totalShare;
    uint256 public burnShare;
    uint256 public extracted;

    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;

    constructor(
        address _owner,
        address _manager,
        address _dust,
        address _rewardToken
    ) {
        owner = _owner;
        manager = _manager;
        dust = _dust;
        rewardToken = _rewardToken;
    }

    mapping(address => UserInfo) private userInfo;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }
    
    /**
     * @notice  .Only the owner can change the owner
     * @dev     .Change the owner
     * @param   _newOwner  .
     */
    function transferOwner(address _newOwner) external onlyOwner {
        address olderOwner = owner;
        owner = _newOwner;
        emit ChangeOwner(olderOwner, owner);
    }
    
    /**
     * @notice  .Only the Owner can change the manager
     * @dev     .Change manager
     * @param   _newManager  .
     */
    function transferManager(address _newManager) external onlyOwner {
        address olderManager = manager;
        manager = _newManager;
        emit ChangeManager(olderManager, manager);
    }

    /**
     * @notice  .
     * @dev     .Owner change the token information
     * @param   _dust  .
     * @param   _rewardToken  .
     */
    function changeConfig(
        address _dust,
        address _rewardToken
    ) external onlyOwner {
        dust = _dust;
        rewardToken = _rewardToken;
    }

    /**
     * @notice  .The pledged quantity must be greater than or equal to 10 ** 18
     * @dev     .Stake DUST to obtain collateral rewards
     * @param   amount  .
     */
    function deposite(uint128 amount) external nonReentrant {
        require(
            amount >= 10 ** _getTokenDecimals(dust),
            "At least more than 10 ** decmials"
        );
        uint256 share;
        if (totalShare == 0 || reserve0 == 0) {
            share = amount - MINIMUM_LIQUIDITY;
        } else {
            share = (amount * totalShare) / reserve0;
        }
        totalPledge += amount;
        _updateReserve();
        IERC20(dust).safeTransferFrom(msg.sender, address(this), amount);
        uint256 stageReserve1Revenue;
        uint256 stageTotalShare;
        uint256 revenue;
        if (userInfo[msg.sender].number > 0) {
            stageReserve1Revenue =
                reserve1 + userInfo[msg.sender].startExtractedAmount - 
                extracted - userInfo[msg.sender].startAmount;
            stageTotalShare =
                totalShare +
                burnShare -
                userInfo[msg.sender].startBurnShare;
            revenue = DustFlowLibrary._getCurrentRevenue(
                share,
                stageTotalShare,
                stageReserve1Revenue,
                userInfo[msg.sender].captureAmount
            );
        }
        if (revenue > 0) {
            userInfo[msg.sender].captureAmount += revenue;
        }

        userInfo[msg.sender].dustAmount += amount;
        userInfo[msg.sender].shareAmount += share;
        userInfo[msg.sender].startExtractedAmount = extracted;
        userInfo[msg.sender].startBurnShare = burnShare;
        userInfo[msg.sender].startAmount = reserve1;
        userInfo[msg.sender].number++;
        emit Deposite(msg.sender, share, amount);
        require(_update(Way.inject, amount, share, revenue), "Update fail");
    }

    /**
     * @notice  .Only when the fees are successfully captured during the pledge period will there be profits
     * @dev     .Extract the staked DUST and reward tokens
     */
    function withdraw() external nonReentrant {
        _updateReserve();
        uint256 userShareAmount = userInfo[msg.sender].shareAmount;
        uint256 userDustAmount = userInfo[msg.sender].dustAmount;
        uint256 stageReserve1Revenue = 
                reserve1 + userInfo[msg.sender].startExtractedAmount - 
                extracted - userInfo[msg.sender].startAmount;
        uint256 stageTotalShare = burnShare -
            userInfo[msg.sender].startBurnShare +
            totalShare;
        uint256 revenue = DustFlowLibrary._getCurrentRevenue(
            userShareAmount,
            stageTotalShare,
            stageReserve1Revenue,
            userInfo[msg.sender].captureAmount
        );

        if (userDustAmount > 0 || revenue > 0) {
            if (userDustAmount > 0) {
                IERC20(dust).safeTransfer(msg.sender, userDustAmount);
            }
            if (revenue > 0) {
                IERC20(rewardToken).safeTransfer(msg.sender, revenue);
            }
        } else {
            revert("ZERO");
        }
        emit Withdraw(msg.sender, revenue);
        delete userInfo[msg.sender];
        require(
            _update(Way.exit, userDustAmount, userShareAmount, revenue),
            "Update fail"
        );
    }

    function _updateReserve() private {
        reserve0 = _getUserTokenBalance(dust, address(this));
        reserve1 = _getUserTokenBalance(rewardToken, address(this));
    }

    function _update(
        Way _way,
        uint256 _dustAmount,
        uint256 _shareAmount,
        uint256 _revenue
    ) private returns (bool state) {
        _updateReserve();
        if (_way == Way.inject) {
            totalPledge += _dustAmount;
            if (totalShare == 0) {
                totalShare = _shareAmount + MINIMUM_LIQUIDITY;
            } else {
                totalShare += _shareAmount;
            }
        } else if (_way == Way.exit) {
            extracted += _revenue;
            burnShare += _shareAmount;
            totalPledge -= _dustAmount;
            totalShare -= _shareAmount;
        } else {
            revert("No way");
        }
        state = true;
    }

    function _checkOwner() private view {
        require(msg.sender == owner, "Non owner");
    }

    function _checkManager() private view {
        require(msg.sender == manager, "Non manager");
    }

    function _getTokenDecimals(
        address token
    ) private view returns (uint8 thisDecimals) {
        thisDecimals = IERC20Metadata(token).decimals();
    }

    function _getUserTokenBalance(
        address token,
        address user
    ) private view returns (uint256 userBalance) {
        userBalance = IERC20(token).balanceOf(user);
    }

    /**
     * @notice  .
     * @dev     .Obtain the quantity that users can extract
     * @param   user  .
     * @return  dustAmount  .
     * @return  rewardAmount  .
     */
    function getAmounts(
        address user
    ) external view returns (uint256 dustAmount, uint256 rewardAmount) {
        uint256 userShareAmount = userInfo[user].shareAmount;
        dustAmount = userInfo[user].dustAmount;
        if (userInfo[msg.sender].number > 0) {
            uint256 stageReserve1Revenue = _getUserTokenBalance(
                rewardToken,
                address(this)
            ) + userInfo[msg.sender].startExtractedAmount - 
                extracted - userInfo[msg.sender].startAmount;
            uint256 stageTotalShare = totalShare +
                burnShare -
                userInfo[user].startBurnShare;
            rewardAmount = DustFlowLibrary._getCurrentRevenue(
                userShareAmount,
                stageTotalShare,
                stageReserve1Revenue,
                userInfo[user].captureAmount
            );
        }
    }

    /**
     * @notice  .
     * @dev     .Obtain the decimals of the token
     * @param   token  .
     * @return  uint8  .
     */
    function getTokenDecimals(address token) external view returns (uint8) {
        return _getTokenDecimals(token);
    }

    /**
     * @notice  .
     * @dev     .Obtain the balance of the token
     * @param   token  .
     * @param   user  .
     * @return  uint256  .
     */
    function getTokenBalance(
        address token,
        address user
    ) external view returns (uint256) {
        return _getUserTokenBalance(token, user);
    }

    /**
     * @notice  .
     * @dev     .Obtain the user's pledge information
     * @param   user  .
     * @return  UserInfo  .
     */
    function getUserInfo(address user) external view returns (UserInfo memory) {
        return userInfo[user];
    }

    /**
     * @notice  .
     * @dev     .Obtain the latest block of the current chain
     * @return  uint256  .
     */
    function getLatestBlock() external view returns (uint256) {
        return block.number;
    }
}
