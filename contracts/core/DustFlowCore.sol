// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IGovernance} from "../interfaces/IGovernance.sol";
import {IDustFlowCore} from "../interfaces/IDustFlowCore.sol";
import {DustFlowLibrary} from "../libraries/DustFlowLibrary.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @author  .One of the members of VineLabs, 0xlive
 * @title   .DustFlowCore
 * @dev     .The main implementation of the DustFlow pre market
 * @notice  .Only administrators can create markets
 */

contract DustFlowCore is ReentrancyGuard, IDustFlowCore {
    using SafeERC20 for IERC20;

    uint256 public currentMarketId;
    uint256 public orderId;

    bytes1 private immutable ZEROBYTES1;
    bytes1 private immutable ONEBYTES1 = 0x01;
    address public governance;
    address public manager;

    uint64 public latestMaxBuyPrice;
    uint64 public latestMinSellPrice;
    uint64 public latestMaxDoneBuyPrice;
    uint64 public latestMaxDoneSellPrice;

    constructor(
        address _governance,
        address _manager,
        uint256 _marketId
    ){
        manager = _manager;
        governance = _governance;
        currentMarketId = _marketId;
    }

    mapping(uint256 => OrderInfo) private orderInfo;
    mapping(address => UserInfo) private userInfo;

    modifier onlyManager{
        require(msg.sender == manager);
        _;
    }

    /**
     * @notice  .It can only be created 12 hours before the market ends, 
     * and the total amount must be greater than or equal to 10$
     * @dev     .Users create orders (buy or sell)
     * @param   _orderType  .
     * @param   _amount  .
     * @param   _price  .
     */
    function putTrade(
        OrderType _orderType,
        uint64 _amount,
        uint64 _price
    ) external nonReentrant {
        _checkOrderCloseState();
        if(_orderType == OrderType.buy){
            orderInfo[orderId].state = OrderState.buying;
            userInfo[msg.sender].buyIdGroup.push(orderId);
            if(_price > latestMaxBuyPrice){
                latestMaxBuyPrice = _price;
            }
        }else {
            orderInfo[orderId].state = OrderState.selling;
            userInfo[msg.sender].sellIdGroup.push(orderId);
            if(_price < latestMinSellPrice){
                latestMinSellPrice = _price;
            }
        }
        orderInfo[orderId].orderType = _orderType;
        address collateral = _getMarketConfig().collateral;
        uint8 collateralDecimals = _tokenDecimals(collateral);
        uint256 totalCollateral = _getCurrentTotalCollateral(_price, _amount);
        require(totalCollateral >= 10 * 10 ** collateralDecimals, "Less 10$");
        IERC20(collateral).safeTransferFrom(msg.sender, address(this), totalCollateral);
        orderInfo[orderId].amount = _amount;
        orderInfo[orderId].price = _price;
        orderInfo[orderId].creator = msg.sender;
        orderInfo[orderId].creationTime = block.timestamp;
        _join();
        emit CreateOrder(orderId, msg.sender, totalCollateral);
        orderId++;
    }

    /**
     * @notice  .Order creators cannot match their own orders. 
     * They can only match orders 12 hours before the market ends, and the purchasers will pay the fees.
     * @dev     .Match the order
     * @param   _orderType  .
     * @param   _amount  .
     * @param   _price  .
     * @param   orderIds  .
     */
    function matchTrade(
        OrderType _orderType,
        uint64 _amount,
        uint64 _price,
        uint256[] calldata orderIds
    ) external nonReentrant {
        _checkOrderCloseState();
        uint256 collateralTokenAmount;
        uint256 totalFee;
        uint64 waitTokenAmount;
        address collateral = _getMarketConfig().collateral;
        unchecked{
            for(uint256 i; i<orderIds.length; i++){
                uint64 remainAmount;
                uint64 currentPrice = orderInfo[orderIds[i]].price;
                address creator = orderInfo[orderIds[i]].creator;
                if(msg.sender != creator){
                    //buy
                    if(_orderType == OrderType.buy){
                        if(orderInfo[orderIds[i]].state == OrderState.selling){
                            if(currentPrice <= _price){
                                remainAmount = orderInfo[orderIds[i]].amount - orderInfo[orderIds[i]].doneAmount;
                                if(remainAmount > 0){
                                    userInfo[msg.sender].buyIdGroup.push(orderIds[i]);
                                    userInfo[creator].sellDoneAmount += remainAmount;
                                    totalFee += DustFlowLibrary._fee(remainAmount, _tokenDecimals(collateral));
                                    if(currentPrice > latestMaxDoneSellPrice){
                                        latestMaxDoneSellPrice = currentPrice;
                                    }
                                }
                            }
                        }
                    }else{
                        //sell
                        if(orderInfo[orderIds[i]].state == OrderState.buying){
                            if(currentPrice >= _price){
                                remainAmount = orderInfo[orderIds[i]].amount - orderInfo[orderIds[i]].doneAmount;
                                if(remainAmount > 0){
                                    userInfo[msg.sender].sellIdGroup.push(orderIds[i]);
                                    userInfo[creator].buyDoneAmount += remainAmount;
                                    if(currentPrice > latestMaxDoneBuyPrice){
                                        latestMaxDoneBuyPrice = currentPrice;
                                    }
                                }
                            }
                        }
                    }
                    if(remainAmount> 0){   
                        if(remainAmount > _amount - waitTokenAmount){
                            orderInfo[orderIds[i]].doneAmount += _amount - waitTokenAmount;
                        }else{
                            orderInfo[orderIds[i]].doneAmount += remainAmount;
                            if(orderInfo[orderIds[i]].doneAmount == orderInfo[orderIds[i]].amount){
                                orderInfo[orderIds[i]].state = OrderState.found;
                            }
                        }
                        orderInfo[orderIds[i]].trader = msg.sender;
                        waitTokenAmount += remainAmount;
                        collateralTokenAmount += _getCurrentTotalCollateral(currentPrice, remainAmount);
                    }
                }else{
                    revert InvalidUser();
                }
            }
        }
        if(waitTokenAmount == 0){revert ZeroQuantity();}
        IERC20(collateral).safeTransferFrom(msg.sender, address(this), collateralTokenAmount);
        _join();
        if(_orderType == OrderType.buy){
            userInfo[msg.sender].buyDoneAmount += waitTokenAmount;
            _safeTransferFee(collateral, totalFee);
        }else{
            userInfo[msg.sender].sellDoneAmount += waitTokenAmount;
        }
        emit MatchOrders(orderIds, _orderType);
        
    }

    /**
     * @notice  .If an order is cancelled 12 hours before the market ends, a 0.5% cancellation fee will be charged.
     * If the order is not matched after the market ends, a refund will not be charged.
     * @dev     .Cancel the orders that did not match successfully
     * @param   orderIds  .
     */
    function cancel(uint256[] calldata orderIds) external nonReentrant {
        _checkOrderCloseState();
        uint256 cancelCollateralTokenAmount;
        unchecked {
            for(uint256 i; i<orderIds.length; i++){
                if(msg.sender == orderInfo[orderIds[i]].creator){
                    if(orderInfo[orderIds[i]].state == OrderState.buying || orderInfo[orderIds[i]].state == OrderState.selling){
                        uint64 remainAmount = orderInfo[orderIds[i]].amount - orderInfo[orderIds[i]].doneAmount;
                        if(remainAmount >0){
                            cancelCollateralTokenAmount += _getCurrentTotalCollateral(orderInfo[orderIds[i]].price, remainAmount);
                        }
                        orderInfo[orderIds[i]].state = OrderState.fail;
                    }
                }
            }
        }
        if(cancelCollateralTokenAmount == 0){revert ZeroQuantity();}
        address collateral = _getMarketConfig().collateral;
        //0.5%
        uint256 fee = cancelCollateralTokenAmount * 5 / 1000;
        IERC20(collateral).safeTransfer(msg.sender, cancelCollateralTokenAmount - fee);
        _safeTransferFee(collateral, fee);
        emit CancelOrders(orderIds);
    }

    /**
     * @notice  .Orders that have been successfully matched need to stake the target token 
     * before the market ends; otherwise, they will default
     * @dev     .Authorize the target token to this market and stake the target token
     * @param   orderIds  .
     */
    function deposite(uint256[] calldata orderIds) external {
        uint256 endTime = _getMarketConfig().endTime;
        if(block.timestamp >= endTime){revert OrderAlreadyClose(block.timestamp);}
        uint256 waitTokenAmount;
        unchecked {
            for(uint256 i; i< orderIds.length; i++){
                uint64 price = orderInfo[orderIds[i]].price;
                uint64 doneAmount = orderInfo[orderIds[i]].doneAmount;
                if(msg.sender == orderInfo[orderIds[i]].creator){
                    if(orderInfo[orderIds[i]].orderType == OrderType.sell && orderInfo[orderIds[i]].state == OrderState.found){
                        waitTokenAmount += _getCurrentTotalTargetAmount(
                            price,
                            doneAmount
                        );
                        userInfo[msg.sender].sellDoneAmount -= doneAmount;
                        orderInfo[orderIds[i]].state = OrderState.done;
                    }
                }else if(msg.sender == orderInfo[orderIds[i]].trader){
                    if(orderInfo[orderIds[i]].orderType == OrderType.buy && orderInfo[orderIds[i]].state == OrderState.found){
                        waitTokenAmount += _getCurrentTotalTargetAmount(
                            price,
                            doneAmount
                        );
                        userInfo[msg.sender].sellDoneAmount -= doneAmount;
                        orderInfo[orderIds[i]].state = OrderState.done;
                    }
                }
            }
        }
        if(waitTokenAmount ==0){revert ZeroQuantity();}
        address waitToken = _getMarketConfig().waitToken;
        IERC20(waitToken).safeTransferFrom(msg.sender, address(this), waitTokenAmount);
        emit DepositeOrders(orderIds);
    }

    /**
     * @notice  .Orders that are not successfully matched after the market ends can be refunded
     * @dev     .refund
     * @param   orderIds  .
     */
    function refund(uint256[] calldata orderIds) external nonReentrant {
        _checkOrderEndState();
        address collateral = _getMarketConfig().collateral;
        uint256 refundAmount;
        unchecked {
            for(uint256 i; i< orderIds.length; i++){
                if(msg.sender == orderInfo[orderIds[i]].creator){
                    if(orderInfo[orderIds[i]].state == OrderState.buying || orderInfo[orderIds[i]].state == OrderState.selling){
                        if(orderInfo[orderIds[i]].creatorWithdrawState == ZEROBYTES1){
                            refundAmount += _getCurrentTotalCollateral(
                                orderInfo[orderIds[i]].price, 
                                orderInfo[orderIds[i]].amount - orderInfo[orderIds[i]].doneAmount
                            );
                            orderInfo[orderIds[i]].creatorWithdrawState = ONEBYTES1;
                        }
                    }
                }
            }
        }
        if(refundAmount == 0){revert ZeroQuantity();}
        IERC20(collateral).safeTransfer(msg.sender, refundAmount);
        emit RefundOrders(orderIds);
    }

    /**
     * @notice  .Orders completed after the market ends can be withdrawn, and the seller will pay the fee
     * @dev     .After the market ends, buyers can withdraw the target token and sellers can withdraw the collateral
     * @param   orderType  .
     * @param   orderIds  .
     */
    function withdraw(OrderType orderType, uint256[] calldata orderIds) external nonReentrant {
        _checkOrderEndState();
        address waitToken = _getMarketConfig().waitToken;
        address collateral = _getMarketConfig().collateral;
        uint8 collateralDecimals = _tokenDecimals(collateral);
        uint256 totalFee;
        uint256 collateralTokenAmount;
        uint256 waitTokenAmount;
        unchecked {
            for(uint256 i; i< orderIds.length; i++){
                uint64 price = orderInfo[orderIds[i]].price;
                uint64 doneAmount = orderInfo[orderIds[i]].doneAmount;
                uint256 thisTotalAmount = _getCurrentTotalCollateral(orderInfo[orderIds[i]].price, doneAmount);
                if(msg.sender == orderInfo[orderIds[i]].creator){
                    if(
                        orderType == OrderType.buy && 
                        orderInfo[orderIds[i]].orderType == orderType && 
                        orderInfo[orderIds[i]].state == OrderState.done
                    ){
                        if(orderInfo[orderIds[i]].creatorWithdrawState == ZEROBYTES1){
                            waitTokenAmount += _getCurrentTotalTargetAmount(
                                price,
                                doneAmount
                            );
                            orderInfo[orderIds[i]].creatorWithdrawState = ONEBYTES1;
                        }
                    } else if(
                        orderType == OrderType.sell && 
                        orderInfo[orderIds[i]].orderType == orderType && 
                        orderInfo[orderIds[i]].state == OrderState.done
                    ){
                        if(orderInfo[orderIds[i]].creatorWithdrawState == ZEROBYTES1){
                            collateralTokenAmount += thisTotalAmount;
                            totalFee += DustFlowLibrary._fee(thisTotalAmount, collateralDecimals);
                            orderInfo[orderIds[i]].creatorWithdrawState = ONEBYTES1;
                        }
                    }
                }else if (msg.sender == orderInfo[orderIds[i]].trader){
                    if(
                        orderType == OrderType.buy && 
                        orderInfo[orderIds[i]].orderType == OrderType.sell && 
                        orderInfo[orderIds[i]].state == OrderState.done
                    ){
                        if(orderInfo[orderIds[i]].traderWithdrawState == ZEROBYTES1){
                            waitTokenAmount += _getCurrentTotalTargetAmount(
                                price,
                                doneAmount
                            );
                            orderInfo[orderIds[i]].traderWithdrawState = ONEBYTES1;
                        }
                    } else if(
                        orderType == OrderType.sell && 
                        orderInfo[orderIds[i]].orderType == OrderType.buy && 
                        orderInfo[orderIds[i]].state == OrderState.done
                    ){
                        if(orderInfo[orderIds[i]].traderWithdrawState == ZEROBYTES1){
                            collateralTokenAmount += thisTotalAmount;
                            totalFee += DustFlowLibrary._fee(thisTotalAmount, collateralDecimals);
                            orderInfo[orderIds[i]].traderWithdrawState = ONEBYTES1;
                        }
                    }
                }else {
                    revert InvalidUser();
                }
            }
        }
       
        if(orderType == OrderType.buy){
            if(waitTokenAmount == 0){revert ZeroQuantity();}
            IERC20(waitToken).safeTransfer(msg.sender, waitTokenAmount);
        // sell pay fee
        }else{
            if(collateralTokenAmount == 0){revert ZeroQuantity();}
            IERC20(collateral).safeTransfer(msg.sender, collateralTokenAmount * 2 - totalFee);
            _safeTransferFee(collateral, totalFee);
        }
        emit WithdrawOrders(orderIds);
    }

    /**
     * @notice  .After the market ends, for orders that are successfully matched, 
     * if the seller has not staked the target token, the buyer will obtain the seller's collateral and pay the fee.
     * @dev     .Default orders after the market ends
     * @param   orderIds  .
     */
    function withdrawLiquidatedDamages(uint256[] calldata orderIds) external {
        _checkOrderEndState();
        address collateral = _getMarketConfig().collateral;
        uint8 collateralDecimals = _tokenDecimals(collateral);
        uint256 liquidatedDamagesAmount;
        uint256 totalFee;
        unchecked {
            for(uint256 i; i< orderIds.length; i++){
                uint256 thisTotalAmount = _getCurrentTotalCollateral(orderInfo[orderIds[i]].price, orderInfo[orderIds[i]].amount);
                if(msg.sender == orderInfo[orderIds[i]].creator){
                    if(orderInfo[orderIds[i]].state == OrderState.found){
                        if(orderInfo[orderIds[i]].orderType == OrderType.buy){
                            if(orderInfo[orderIds[i]].creatorWithdrawState == ZEROBYTES1){
                                liquidatedDamagesAmount += thisTotalAmount;
                                totalFee += DustFlowLibrary._fee(thisTotalAmount, collateralDecimals);
                                orderInfo[orderIds[i]].creatorWithdrawState = ONEBYTES1; 
                            }
                        }
                    }
                }else if(msg.sender == orderInfo[orderIds[i]].trader){
                    if(orderInfo[orderIds[i]].state == OrderState.found){
                        if(orderInfo[orderIds[i]].orderType == OrderType.sell){
                            if(orderInfo[orderIds[i]].traderWithdrawState == ZEROBYTES1){
                                liquidatedDamagesAmount += thisTotalAmount;
                                totalFee += DustFlowLibrary._fee(thisTotalAmount, collateralDecimals);
                                orderInfo[orderIds[i]].traderWithdrawState = ONEBYTES1;
                            }
                        }
                    }
                }else{
                    revert InvalidUser();
                }
            }
        }
        if(liquidatedDamagesAmount == 0){revert ZeroQuantity();}
        IERC20(collateral).safeTransfer(msg.sender, liquidatedDamagesAmount * 2 - totalFee);
        _safeTransferFee(collateral, totalFee);
        emit WithdrawLiquidatedDamages(orderIds);
    }

    function _getMarketConfig() private view returns(IGovernance.MarketConfig memory) {
        return IGovernance(governance).getMarketConfig(currentMarketId);
    }

    function _tokenDecimals(address token) private view returns(uint8) {
        return IERC20Metadata(token).decimals();
    }

    function _getCurrentTotalCollateral(uint64 _price , uint64 _amount) private pure returns(uint256 _totalCollateral) {
        _totalCollateral = DustFlowLibrary._getTotalCollateral(
            _price,
            _amount
        );
    }

    function _getCurrentTotalTargetAmount(uint64 _price , uint64 _amount) private view returns(uint256 _totalTargetAmount) {
        address targetToken  =  _getMarketConfig().waitToken;
        address collateral =  _getMarketConfig().collateral;
        uint8 targetTokenDecimals = _tokenDecimals(targetToken);
        uint8 collateralDecimals = _tokenDecimals(collateral);
        _totalTargetAmount = DustFlowLibrary._getTargetTokenAmount(
            targetTokenDecimals,
            collateralDecimals,
            _price,
            _amount
        );
    }

    function _getFeeInfo() private view returns(IGovernance.FeeInfo memory) {
        return IGovernance(governance).getFeeInfo();
    }

    function _safeTransferFee(address collateral, uint256 fee) private {
        uint256 dustFee = fee *  _getFeeInfo().rate / 100;
        uint256 protocolFee = fee * (100 -  _getFeeInfo().rate) / 100;
        address dustPool = _getFeeInfo().dustPool;
        address feeReceiver = _getFeeInfo().feeReceiver;
        //transfer to dust
        IERC20(collateral).safeTransfer(dustPool, dustFee);
        //transfer to feeReceiver
        IERC20(collateral).safeTransfer(feeReceiver, protocolFee);
    }

    function _checkOrderCloseState() private view {
        if(block.timestamp + 12 hours >= _getMarketConfig().endTime){revert OrderAlreadyClose(block.timestamp);}
    }

    function _checkOrderEndState() private view {
        uint256 endTime = _getMarketConfig().endTime;
        if(endTime == 0 || block.timestamp <= endTime){revert NotEnd(block.timestamp);}
    }

    function _join() private {
        IGovernance(governance).join(msg.sender, currentMarketId);
    }

    /**
     * @notice  .Obtain the information of the order structure
     * @dev     .Pass in a valid order id to obtain the order information
     * @param   thisOrderId  .
     * @return  OrderInfo  
     */
    function getOrderInfo(uint256 thisOrderId) external view returns(OrderInfo memory) {
        return orderInfo[thisOrderId];
    }

    /**
     * @notice  .Obtain the information of users buying or selling
     * @dev     .Pass in the user's address to obtain the user's buy or sell information
     * @param   user  .
     * @return  thisBuyDoneAmount  .
     * @return  thisSellDoneAmount  .
     */
    function getUserInfo(address user) external view returns (
        uint128 thisBuyDoneAmount,
        uint128 thisSellDoneAmount
    ){
        thisBuyDoneAmount = userInfo[user].buyDoneAmount;
        thisSellDoneAmount = userInfo[user].sellDoneAmount;
    }

    /**
     * @notice  .Index the order id purchased by the user
     * @dev     .Pass in the user's address and index to obtain the order id of the user's purchase
     * @param   user  .
     * @param   index  .
     */
    function indexUserBuyId(address user, uint256 index) external view returns(uint256 buyId) {
        buyId = userInfo[user].buyIdGroup[index];
    }

    /**
     * @notice  .Index the order id sold by the user
     * @dev     .Pass in the user address and index to obtain the order id sold by the user
     * @param   user  .
     * @param   index  .
     */
    function indexUserSellId(address user, uint256 index) external view returns(uint256 sellId) {
        sellId = userInfo[user].sellIdGroup[index];
    }

    /**
     * @notice  .Obtain the length of the user's purchased id array
     * @dev     .Used to index the correct array of purchase ids
     * @param   user  .
     */
    function getUserBuyIdsLength(address user) external view returns(uint256) {
        return userInfo[user].buyIdGroup.length;
    }

    /**
     * @notice  .Obtain the length of the array of user sold ids
     * @dev     .Used to index the correct array of sale ids
     * @param   user  .
     */
    function getUserSellIdsLength(address user) external view returns(uint256) {
        return userInfo[user].sellIdGroup.length;
    }
    
}