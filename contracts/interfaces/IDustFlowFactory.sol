// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
interface IDustFlowFactory {
    
    struct MarketInfo{
        address market;
        uint64 createTime;
    }
    event CreateMarket(uint256 indexed id, address market);

    function marketId() external view returns(uint256);

    function getMarketInfo(uint256 id) external view returns(MarketInfo memory);

}
    