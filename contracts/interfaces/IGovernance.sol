// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IGovernance{
    
    struct FeeInfo{
        address feeReceiver;
        address dustPool;
        uint8 rate;
    }
    
    struct MarketConfig {
        address waitToken;
        address collateral;
        uint256 endTime;
    }

    event UpdateOwner(address oldOwner, address newOwner);
    event UpdateManager(address oldManager, address newManager);

    function join(address user, uint256 marketId) external;

    function owner() external view returns(address);
    function manager() external view returns(address);
    function getFeeInfo() external view returns(FeeInfo memory);
    function getMarketConfig(uint256 marketId) external view returns(MarketConfig memory);
    function getUserJoinMarketLength(address user) external view returns(uint256 len);
    function indexUserJoinInfoGroup(address user, uint256 index) external view returns(uint256 marketId);

}