// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IDustFlowFactory} from "../interfaces/IDustFlowFactory.sol";
import {IGovernance} from "../interfaces/IGovernance.sol";
import {DustFlowCore} from "./DustFlowCore.sol";

/**
 * @author  .One of the members of VineLabs, 0xlive
 * @title   .DustFlowFactory
 * @dev     .Used to create the DustFlow marketplace
 * @notice  .Only administrators can create new markets
 */

contract DustFlowFactory is IDustFlowFactory {

    uint256 public marketId;
    address private governance;

    constructor(address _governance) {
        governance = _governance;
    }

    mapping(uint256 => MarketInfo) private marketInfo;

    /**
     * @notice  .Only administrators can create new markets
     * @dev     .Create a new market
     */
    function createMarket() external {
        address currentManager = IGovernance(governance).manager();
        require(msg.sender == currentManager);
        address newDustFlowCore = address(
            new DustFlowCore{
                salt: keccak256(abi.encodePacked(marketId, block.timestamp, block.chainid))
            }(governance, currentManager, marketId)
        );
        marketInfo[marketId] = MarketInfo({
            market: newDustFlowCore,
            createTime: uint64(block.timestamp)
        });
        emit CreateMarket(marketId, newDustFlowCore);
        marketId++;
        require(newDustFlowCore != address(0), "Zero address");
    }

    
    /**
     * @notice  .Obtain the market information that has been created
     * @dev     .Used to find the market address that has been created
     * @param   id  .
     */
    function getMarketInfo(uint256 id) external view returns(MarketInfo memory) {
        return marketInfo[id];
    }
}