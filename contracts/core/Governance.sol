// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IGovernance} from "../interfaces/IGovernance.sol";
import {IDustFlowFactory} from "../interfaces/IDustFlowFactory.sol";
contract Governance is IGovernance {
    
    address public owner;
    address public manager;
    address public collateral;
    address public dustFlowFactory;
    
    
    mapping(address => FeeInfo) private feeInfo;

    constructor(
        address _owner, 
        address _manager,
        address _collateral,
        address _dustPool,
        address _feeReceiver
    )
    {
        owner = _owner;
        manager = _manager;
        collateral = _collateral;
        feeInfo[address(this)] = FeeInfo({
            feeReceiver: _feeReceiver,
            dustPool: _dustPool,
            rate: 50
        });
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }

    mapping(uint256 => MarketConfig) private marketConfig;
    mapping(address => mapping(uint256 => bool)) private userJoinInfoState;
    mapping(address => uint256[]) private userJoinInfoGroup;

    function changeOwner(address _newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = _newOwner;
        emit UpdateOwner(oldOwner, _newOwner);
    }

    function changeManager(address _newManager) external onlyOwner {
        address oldManager = manager;
        manager = _newManager;
        emit UpdateManager(oldManager, _newManager);
    }
    function changeFeeInfo(
        address newFeeReceiver,
        address newDustPool,
        uint8 newRate
    ) external onlyOwner {
        require(newRate < 100, "Invalid rate");
        feeInfo[address(this)].feeReceiver = newFeeReceiver;
        feeInfo[address(this)].dustPool = newDustPool;
        feeInfo[address(this)].rate = newRate;
    }

    function setMarketConfig(
        uint256 _marketId, 
        uint256 _endTime,
        address _waitToken
    ) external onlyManager {
        marketConfig[_marketId].waitToken = _waitToken;
        marketConfig[_marketId].endTime = _endTime + block.timestamp;
        marketConfig[_marketId].collateral = collateral;
    }
    
    function changeCollateral(
        address _collateral
    ) external onlyManager {
        collateral = _collateral;
    }

    function changeDustFlowFactory(
        address _dustFlowFactory
    ) external onlyManager {
        dustFlowFactory = _dustFlowFactory;
    }
    
    function join(address user, uint256 marketId) external {
        require(msg.sender == IDustFlowFactory(dustFlowFactory).getMarketInfo(marketId).market, "Invalid market");
        if(userJoinInfoState[user][marketId] == false){
            userJoinInfoGroup[user].push(marketId);
            userJoinInfoState[user][marketId] = true;
        }
    }

    function _checkOwner() private view {
        require(msg.sender == owner, "Non owner");
    }

    function _checkManager() private view {
        require(msg.sender == manager, "Non manager");
    }

    function getFeeInfo() external view returns(FeeInfo memory) {
        return feeInfo[address(this)];
    }

    function getMarketConfig(uint256 marketId) external view returns(MarketConfig memory) {
        return marketConfig[marketId];
    }
    
    function getUserJoinMarketLength(address user) public view returns(uint256 len) {
        len = userJoinInfoGroup[user].length;
    }

    function indexUserJoinInfoGroup(address user, uint256 index) public view returns(uint256 marketId) {
        marketId = userJoinInfoGroup[user][index];
    }

    
}
