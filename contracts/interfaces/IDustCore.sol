// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IDustCore {
    enum FlowWay {
        doTransfer,
        flow
    }

    enum UserFlowState {
        sendFlow,
        receiveFlow
    }

    struct DustFlowInfo {
        FlowWay way;
        address sender;
        address receiver;
        address flowToken;
        uint64 startTime;
        uint64 endTime;
        uint128 amount;
        uint128 doneAmount;
        uint256 lastestWithdrawTime;
    }

    error AmountErr(bytes1);
    error AaveSupplyErr(string);
    error AaveWithdrawErr(string);
    error MintErr(string);
    error BurnErr(string);

    event ChangeOwner(address older, address newer);
    event ChangeManager(address older, address newer);
    event Initialize(bytes1 state);
    event LockEvent(bytes1 state);
    event ChangeFeeInfo(address newFeeReceier, uint16 newFee);
    event UpdateAave(
        uint16 currentReferralCode,
        address aavePoolAddress
    );
    event UpdateComt(address comt, address rewards);
    event Blacklist(address blacklist, bool state);
    event ClaimCompoundRewards(address thisReceiver);
    event MintDUST(
        address receiver,
        uint256 collateralAmount,
        uint256 dustAmount
    );
    event Refund(
        address receiver,
        uint256 collateralAmount,
        uint256 dustAmount
    );
    event Flow(
        FlowWay indexed way,
        address indexed sender,
        address receiver,
        uint256 amount
    );
    event FlowReceive(address receiver, address token, uint256 amount);

    function transferOwner(address _newOwner) external;

    function transferManager(address _newManager) external;

    function setFeeInfo(
        uint16 _feeRate,
        address _feeReceiver,
        address _dustPool
    ) external;

    function initialize(address thisCollateral) external;

    function setLockState(bytes1 state) external;

    function setBlacklist(
        address[] calldata blacklistGroup,
        bool[] calldata states
    ) external;

    function mintDust(uint256 amount) external;

    function refund(uint256 amount) external;

    function flow(
        FlowWay way,
        uint64 endTime,
        uint128 amount,
        address receiver,
        address token
    ) external;

    function receiveDustFlow(uint256 id) external;

    function lockState() external view returns (bytes1);
    function initializeState() external view returns (bytes1);
    function referralCode() external view returns (uint16);
    function feeRate() external view returns (uint16);
    function owner() external view returns (address);
    function manager() external view returns (address);
    function collateral() external view returns (address);
    function feeReceiver() external view returns (address);
    function dustPool() external view returns (address);
    function flowId() external view returns (uint256);
    function totalCollateral() external view returns (uint256);
    function getChainTimestamp() external view returns (uint256);

    function getUserFlowId(
        address user,
        UserFlowState state,
        uint256 index
    ) external view returns (uint256);

    function getUserFlowIdsLength(
        address user,
        UserFlowState state
    ) external view returns (uint256);

    function getDustFlowInfo(
        uint256 id
    ) external view returns (DustFlowInfo memory);

    function getTokenDecimals(address token) external view returns (uint8);

    function getTokenBalance(
        address token,
        address user
    ) external view returns (uint256);

    function getReceiveAmount(
        uint256 id
    ) external view returns (uint128 remainAmount);
}
