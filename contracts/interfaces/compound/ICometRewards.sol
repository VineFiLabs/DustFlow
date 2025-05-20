// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.11;

import "../../libraries/compound/CometStructs.sol";
interface ICometRewards {
  function getRewardOwed(address comet, address account) external returns (CometStructs.RewardOwed memory);
  function claim(address comet, address src, bool shouldAccrue) external;
}