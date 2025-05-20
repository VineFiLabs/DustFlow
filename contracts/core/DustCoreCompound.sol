// // SPDX-License-Identifier: GPL-3.0
// pragma solidity ^0.8.23;

// import {Dust} from "./Dust.sol";
// import {IDustCore} from "../interfaces/IDustCore.sol";
// import {ICometMainInterface} from "../interfaces/compound/ICometMainInterface.sol";
// import {ICometRewards} from "../interfaces/compound/ICometRewards.sol";

// import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// /**
//  * @title DUST Stablecoin core contract
//  * @notice The collateral will directly enter compoundV3 to generate additional benefits for DUST. Meanwhile,
//  * any Token can be used to perform secure transfers and stream payments with the help of DUST's Flow feature
//  * @author One of the members of VineLabs, 0xlive
//  */

// contract DustCoreCompound is Dust, ReentrancyGuard, IDustCore {
//     using SafeERC20 for IERC20;

    
//     bytes1 private immutable ZEROBYTES1;
//     bytes1 private immutable ONEBYTES1 = 0x01;
//     bytes1 public lockState;
//     bytes1 public initializeState;
//     address public owner;
//     address public manager;
//     address public collateral;
//     address public cometAddress;
//     address public comtRewards;

//     uint64 public fee;
//     address public feeReceiver;

//     uint256 public flowId;
//     uint256 public totalCollateral;

//     constructor(
//         address _cometAddress,
//         address _owner, 
//         address _manager, 
//         address _feeReceiver, 
//         uint64 _fee
//     ) {
//         cometAddress = _cometAddress;
//         owner = _owner;
//         manager = _manager;
//         feeReceiver = _feeReceiver;
//         fee = _fee;
//     }

//     modifier onlyOwner() {
//         _checkOwner();
//         _;
//     }

//     modifier onlyManager() {
//         _checkManager();
//         _;
//     }

//     modifier Lock() {
//         require(lockState == ZEROBYTES1, "Locked");
//         _;
//     }


//     mapping(address => bool) private blacklist;
//     mapping(uint256 => DustFlowInfo) private dustFlowInfo;
//     mapping(address => mapping(UserFlowState => uint256[])) private userFlowId;

//     function transferOwner(address _newOwner) external onlyOwner {
//         address olderOwner = owner;
//         owner = _newOwner;
//         emit ChangeOwner(olderOwner, owner);
//     }

//     function transferManager(address _newManager) external onlyOwner {
//         address olderManager = manager;
//         manager = _newManager;
//         emit ChangeManager(olderManager, manager);
//     }

//     function setCometAddress(address _newCometAddress, address _newComtRewards) external onlyOwner {
//         cometAddress = _newCometAddress;
//         comtRewards = _newComtRewards;
//         emit UpdateComt(cometAddress, comtRewards);
//     }
    
//     function setFeeInfo(address _feeReceiver, uint64 _fee) external onlyOwner {
//         feeReceiver = _feeReceiver;
//         fee = _fee;
//         emit ChangeFeeInfo(_feeReceiver, _fee);
//     }

//     function initialize(address thisCollateral) external onlyManager {
//         require(initializeState == ZEROBYTES1, "Already initialize");
//         collateral = thisCollateral;
//         initializeState = ONEBYTES1;
//         emit Initialize(initializeState);
//     }

//     function setLockState(bytes1 state) external onlyManager {
//         lockState = state;
//         emit LockEvent(state);
//     }

//     function setBlacklist(address[] calldata blacklistGroup, bool[] calldata states) external onlyManager {
//         unchecked {
//             for(uint256 i; i<blacklistGroup.length; i++){
//                 blacklist[blacklistGroup[i]] = states[i];
//                 emit Blacklist(blacklistGroup[i], states[i]);
//             }
//         }
//     }
//     function claimCometRewards(address rewardsContract, address receiver) external onlyManager {
//         ICometRewards(rewardsContract).claim(cometAddress, receiver, true);
//         emit ClaimCompoundRewards(receiver);
//     }

//     function mintDust(
//         uint128 amount
//     ) external Lock nonReentrant {
//         _checkBlacklist(msg.sender);
//         uint256 mintAmount;
//         uint8 collateralDecimals = getTokenDecimals(collateral);
//         uint8 dustDecimals = decimals();
//         if(collateralDecimals > 0){
            // if(collateralDecimals > dustDecimals){
            //         mintAmount = amount / 10 ** (collateralDecimals - dustDecimals);
            //     }else if(collateralDecimals < dustDecimals){
            //         mintAmount = amount * 10 ** (dustDecimals - collateralDecimals);
            //     }else{
            //         mintAmount = amount;
            //     }
            // }
//         require(mintAmount > 10 ** dustDecimals, "Amount err");
//         IERC20(collateral).safeTransferFrom(msg.sender, address(this), amount);
//         uint256 collateralBalance = getUserTokenbalance(collateral, address(this));
//         if(collateralBalance > 0){
//             IERC20(collateral).approve(cometAddress, collateralBalance);
//             ICometMainInterface(cometAddress).supply(collateral, collateralBalance);
//             totalCollateral += amount;
//             emit MintDUST(msg.sender, amount, mintAmount);
//             require(_mint(msg.sender, mintAmount), "Mint fail");
//         }else {
//             revert ("Zero");
//         }
//     }

//     function refund(
//         uint128 amount
//     ) external nonReentrant {
//         uint256 refundAmount;
//         uint8 collateralDecimals = getTokenDecimals(collateral);
//         uint8 dustDecimals = decimals();
//         if(collateralDecimals > 0){
//             if(collateralDecimals > decimals()){
//                 refundAmount = amount * 10 ** (collateralDecimals - dustDecimals);
//             }else if(collateralDecimals < decimals()){
//                 refundAmount = amount / 10 ** (dustDecimals - collateralDecimals);
//             }else{
//                 refundAmount = amount;
//             }
//         }
//         require(refundAmount > 0, "Amount err");
//         ICometMainInterface(cometAddress).withdraw(collateral, refundAmount);
//         IERC20(collateral).safeTransfer(msg.sender, refundAmount);
//         emit Refund(msg.sender, refundAmount, amount);
//         require(_burn(msg.sender, amount), "Burn fail");
//     }

//     function flow(
//         FlowWay way,
//         uint64 endTime,
//         uint128 amount,
//         address receiver,
//         address token
//     ) external nonReentrant {
//         _checkBlacklist(receiver);
//         uint64 currentTime = uint64(block.timestamp);
//         uint64 thisEndTime = currentTime + endTime;
//         require(receiver != address(0) && receiver != address(this) && receiver != msg.sender, "Invalid receiver");
//         if (way == FlowWay.doTransfer) {
//             IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
//             IERC20(token).safeTransfer(receiver, amount);
//         } else if (way == FlowWay.flow) {
//             require(amount >= 10 ** 18, "At least 10 ** 18 dust");
//             require(thisEndTime - 60 >= currentTime, "Invalid endTime");
//             userFlowId[msg.sender][UserFlowState.sendFlow].push(flowId);
//             userFlowId[receiver][UserFlowState.receiveFlow].push(flowId);
//             if(token == address(this)){
//                 require(_burn(msg.sender, amount), "Burn fail");
//             }else{
//                 IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
//                 if(token == collateral){
//                     uint256 collateralBalance = getUserTokenbalance(collateral, address(this));
//                     if(collateralBalance > 0){
//                         IERC20(collateral).approve(cometAddress, collateralBalance);
//                         ICometMainInterface(cometAddress).supply(collateral, collateralBalance);
//                         totalCollateral += amount;
//                     }else {
//                         revert ("Zero");
//                     }
//                 }
//             }
//             dustFlowInfo[flowId] = DustFlowInfo({
//                 way: way,
//                 sender: msg.sender,
//                 receiver: receiver,
//                 flowToken: token,
//                 startTime: currentTime,
//                 endTime: thisEndTime,
//                 amount: amount,
//                 doneAmount: 0,
//                 lastestWithdrawTime: 0
//             });
//             flowId++;
//         } else {
//             revert("Invalid way");
//         }
//         emit Flow(way, msg.sender, receiver, amount);
//     }

//     function receiveDustFlow(uint256 id) external nonReentrant {
//         address receiver = dustFlowInfo[id].receiver;
//         address token = dustFlowInfo[id].flowToken;
//         require(msg.sender == receiver, "Not this receiver");
//         uint128 withdrawAmount = getReceiveAmount(id);
//         require(withdrawAmount > 0, "All completed");
//         dustFlowInfo[id].doneAmount += withdrawAmount;
//         dustFlowInfo[id].lastestWithdrawTime = block.timestamp;
//         require(dustFlowInfo[id].doneAmount <= dustFlowInfo[id].amount, "Amount overflow");
//         if(token == address(this)){
//             require(_mint(receiver, withdrawAmount), "Mint fail");
//         }else {
//             IERC20(token).safeTransfer(receiver, withdrawAmount);
//         }
//         emit FlowReceive(receiver, token, withdrawAmount);
//     }

//     function _checkOwner() private view {
//         require(msg.sender == owner, "Non owner");
//     }

//     function _checkManager() private view {
//         require(msg.sender == manager, "Non manager");
//     }

//     function _checkBlacklist(address user) private view {
//         require(blacklist[user] == false, "blacklist");
//     }

//     function getUserFlowId(address user, UserFlowState state, uint256 index) external view returns (uint256) {
//         return userFlowId[user][state][index];
//     }

//     function getChainTimestamp() external view returns(uint256) {
//         return block.timestamp;
//     }

//     /*
//     * Gets the amount of reward tokens due to this contract address
//     */
//     function getRewardsOwed(address rewardsContract) external returns (CometStructs.RewardOwed) {
//         return ICometRewards(rewardsContract).getRewardOwed(cometAddress, address(this)).owed;
//     }

//     function getUserFlowIdsLength(address user, UserFlowState state) external view returns (uint256) {
//         return userFlowId[user][state].length;
//     }

//     function getDustFlowInfo(
//         uint256 id
//     ) external view returns (DustFlowInfo memory) {
//         return dustFlowInfo[id];
//     }

//     function getTokenDecimals(address token) public view returns (uint8) {
//         return IERC20Metadata(token).decimals();
//     }

//     function getUserTokenbalance(
//         address token,
//         address user
//     ) public view returns (uint256) {
//         return IERC20(token).balanceOf(user);
//     }

//     function getReceiveAmount(
//         uint256 id
//     ) public view returns (uint128 remainAmount) {
//         uint64 startTime = dustFlowInfo[id].startTime;
//         uint64 endTime = dustFlowInfo[id].endTime;
//         uint128 amount = dustFlowInfo[id].amount;
//         uint128 doneAmount = dustFlowInfo[id].doneAmount;
//         uint256 lastestWithdrawTime = dustFlowInfo[id].lastestWithdrawTime;
//         if(endTime - startTime > 0){
//             if(amount >= doneAmount){
//                 uint128 quantityPerSecond = amount / (endTime - startTime);
//                 if (block.timestamp >= endTime) {
//                     remainAmount = amount - doneAmount;
//                 } else {
//                     if(lastestWithdrawTime == 0){
//                         remainAmount = uint128((block.timestamp - startTime) *
//                         quantityPerSecond);
//                     }else{
//                         if(lastestWithdrawTime > startTime && lastestWithdrawTime < endTime) {
//                             remainAmount = uint128((block.timestamp - lastestWithdrawTime) *
//                         quantityPerSecond);
//                         }
//                     }
                    
//                 }
//             }
//         }
//     }

//     function indexUserSenderFlowInfos(
//         UserFlowState state,
//         address user,
//         uint256 pageIndex
//     ) external view returns (
//         DustFlowInfo[] memory dustFlowInfoGroup,
//         uint128[] memory receiveAmountGroup
//     ) {
//         uint256 flowIdsLength = userFlowId[user][state].length;
//         if (flowIdsLength > 0) {
//             uint256 len;
//             uint256 idIndex;
//             uint256 currentUserFlowId;
//             require(pageIndex <= flowIdsLength / 10, "PageIndex overflow");
//             if (flowIdsLength <= 10) {
//                 len = flowIdsLength;
//             } else {
//                 if (flowIdsLength % 10 == 0) {
//                     len = 10;
//                 } else {
//                     len = flowIdsLength % 10;
//                 }
//                 if (pageIndex > 0) {
//                     idIndex = pageIndex * 10;
//                     currentUserFlowId = userFlowId[user][state][idIndex];
//                 }
//             }
//             dustFlowInfoGroup = new DustFlowInfo[](len);
//             receiveAmountGroup = new uint128[](len);
//             unchecked {
//                 for (uint256 i; i < len; i++) {
//                     dustFlowInfoGroup[i] = dustFlowInfo[
//                         currentUserFlowId
//                     ];
//                     receiveAmountGroup[i] = getReceiveAmount(currentUserFlowId);
//                     currentUserFlowId++;
//                 }
//             }
//         }
//     }
// }
