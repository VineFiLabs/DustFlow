// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IGovernance} from "../interfaces/IGovernance.sol";
import {IDustCore} from "../interfaces/IDustCore.sol";
import {IDustFlowCore} from "../interfaces/IDustFlowCore.sol";
import {IDustFlowFactory} from "../interfaces/IDustFlowFactory.sol";
import {DustFlowLibrary} from "../libraries/DustFlowLibrary.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @author  .One of the members of VineLabs, 0xlive
 * @title   .DustFlow Helper
 * @dev     .Used to obtain some data of DustFlow
 */
contract DustFlowHelper {

    bytes1 private immutable ZEROBYTES1;
    bytes1 private immutable ONEBYTES1 = 0x01;
    address public governance;
    address public dustFlowFactory;
    address public owner;

    constructor(address _governance, address _dustFlowFactory){
        governance = _governance;
        dustFlowFactory = _dustFlowFactory;
        owner = msg.sender;
    }

    enum OrderCurrentState{
        inexistence,
        trading,
        found,
        refund,
        absenteeism,
        done
    }

    function changeConfig(address _governance, address _dustFlowFactory) external {
        require(msg.sender == owner, "Non owner");
        governance = _governance;
        dustFlowFactory = _dustFlowFactory;
    }

    /**
     * @notice  .Efficient market
     * @dev     .Obtain the latest pre-prepared order id under the market id
     * @param   marketId  .
     */
    function getLastestOrderId(uint256 marketId) public view returns(uint256){
        address market = _getMarket(marketId);
        return IDustFlowCore(market).orderId();
    }

    /**
     * @notice  .
     * @dev     .Obtain the latest pre-created market id
     */
    function getLastestMarketId() public view returns(uint256){
        return IDustFlowFactory(dustFlowFactory).marketId();
    } 

    /**
     * @notice  .
     * @dev     .
     * @param   marketId  .
     * @param   orderIds  .
     */
    function getOrdersInfo(uint256 marketId, uint256[] calldata orderIds) external view returns(
        OrderCurrentState[] memory orderCurrentStateGroup,
        IDustFlowCore.OrderInfo[] memory orderInfoGroup
    ){
        uint256 len = orderIds.length;
        orderInfoGroup = new IDustFlowCore.OrderInfo[](len);
        orderCurrentStateGroup = new OrderCurrentState[](len);
        unchecked {
            for(uint256 i; i<len; i++){
                orderCurrentStateGroup[i] = getOrderState(marketId, orderIds[i]);
                orderInfoGroup[i] = getOrderInfo(marketId, orderIds[i]);
            }
        }
    }

    /**
     * @notice  .
     * @dev     .
     * @param   pageIndex  .
     */
    function getMarketInfo(
        uint256 pageIndex
    ) external view returns(
        IDustFlowFactory.MarketInfo[] memory marketInfoGroup,
        IGovernance.MarketConfig[] memory marketConfigGroup
    ){  
        uint256 lastestMarketId = getLastestMarketId();
        if(lastestMarketId > 0){
            require(pageIndex <= lastestMarketId / 10, "Page index overflow");
            uint256 len;
            uint256 currentMarketId;
            if(lastestMarketId <= 10){
                len = lastestMarketId;
            }else {
                if(lastestMarketId % 10 == 0){
                    len = 10;
                }else{
                    len = lastestMarketId % 10;
                }
                if(pageIndex !=0 ){
                    currentMarketId = pageIndex * 10;
                }
            }
            marketInfoGroup = new IDustFlowFactory.MarketInfo[](len);
            marketConfigGroup = new IGovernance.MarketConfig[](len);
            unchecked {
                for(uint256 i; i<len; i++){
                    marketInfoGroup[i] = IDustFlowFactory(dustFlowFactory).getMarketInfo(currentMarketId);
                    marketConfigGroup[i] = IGovernance(governance).getMarketConfig(currentMarketId);
                    currentMarketId++;
                }
            }
        }
    }

    /**
     * @notice  .
     * @dev     .
     * @param   marketId  .
     * @param   pageIndex  .
     */
    function getMarketOrderInfos(
        uint256 marketId, 
        uint256 pageIndex
    ) external view returns(IDustFlowCore.OrderInfo[] memory orderInfoGroup){
        uint256 lastestOrderId = getLastestOrderId(marketId);
        if(lastestOrderId > 0){
            require(pageIndex <= lastestOrderId / 10, "Page index overflow");
            uint256 len;
            uint256 currentOrderId;
            if(lastestOrderId <= 10){
                len = lastestOrderId;
            }else {
                if(lastestOrderId % 10 == 0){
                    len = 10;
                }else{
                    len = lastestOrderId % 10;
                }
                if(pageIndex !=0 ){
                    currentOrderId = pageIndex * 10;
                }
            }
            orderInfoGroup = new IDustFlowCore.OrderInfo[](len);
            unchecked {
                for(uint256 i; i<len; i++){
                    orderInfoGroup[i] = getOrderInfo(marketId, currentOrderId);
                    currentOrderId++;
                }
            }
        }
    }

    /**
     * @notice  .
     * @dev     .
     * @param   marketId  .
     * @param   orderId  .
     */
    function getOrderInfo(uint256 marketId, uint256 orderId) public view returns(IDustFlowCore.OrderInfo memory){
        address market = _getMarket(marketId);
        return IDustFlowCore(market).getOrderInfo(orderId);
    }

    /**
     * @notice  .
     * @dev     .
     * @param   marketId  .
     * @param   user  .
     */
    function getMarketUserInfo(uint256 marketId, address user) external view returns(
        uint128 buyDoneAmount,
        uint128 sellDoneAmount
    ){
        address market = _getMarket(marketId);
        (buyDoneAmount, sellDoneAmount) = IDustFlowCore(market).getUserInfo(user);
    }

    /**
     * @notice  .
     * @dev     .
     * @param   marketId  .
     */
    function getMarketLastestPriceInfo(uint256 marketId) external view returns(
        uint64 thisLatestMaxBuyPrice,
        uint64 thisLatestMinSellPrice,
        uint64 thisLatestMaxDoneBuyPrice,
        uint64 thisLatestMaxDoneSellPrice
    ){
        address market = _getMarket(marketId);
        thisLatestMaxBuyPrice = IDustFlowCore(market).latestMaxBuyPrice();
        thisLatestMinSellPrice = IDustFlowCore(market).latestMinSellPrice();
        thisLatestMaxDoneBuyPrice = IDustFlowCore(market).latestMaxDoneBuyPrice();
        thisLatestMaxDoneSellPrice = IDustFlowCore(market).latestMaxDoneSellPrice();
    }

    /**
     * @notice  .
     * @dev     .
     * @param   user  .
     * @param   pageIndex  .
     */
    function getUserJoinMarkets(address user, uint256 pageIndex) external view returns(uint256[] memory marketIds) {
         uint256 joinMarketLen = IGovernance(governance).getUserJoinMarketLength(user);
        if(joinMarketLen > 0){
            require(pageIndex <= joinMarketLen / 10, "Page index overflow");
            uint256 len;
            uint256 indexId;
            if(joinMarketLen <= 10){
                len = joinMarketLen;
            }else {
                if(joinMarketLen % 10 == 0){
                    len = 10;
                }else{
                    len = joinMarketLen % 10;
                }
                if(pageIndex !=0 ){
                    indexId = pageIndex * 10;
                }
            }
            marketIds = new uint256[](len);
            unchecked {
                for(uint256 i; i<len; i++){
                    marketIds[i] = IGovernance(governance).indexUserJoinInfoGroup(user, indexId);
                    indexId++;
                }
            }
        }
    }

    /**
     * @notice  .
     * @dev     .
     * @param   marketId  .
     * @param   user  .
     * @param   pageIndex  .
     */
    function indexUserBuyIds(
        uint256 marketId, 
        address user, 
        uint16 pageIndex
    ) external view returns(uint256[] memory buyIdGroup) {
        uint256 len;
        uint256 currentId;
        address market = _getMarket(marketId);
        uint256 buyIdsLength = IDustFlowCore(market).getUserBuyIdsLength(user);
        require(pageIndex <= buyIdsLength / 10, "Page index overflow");
        if(buyIdsLength >0 ){
            if(buyIdsLength <= 10){
                len = buyIdsLength;
            }else {
                if(buyIdsLength % 10 == 0){
                    len = 10;
                }else {
                    len = buyIdsLength % 10;
                }
                if(pageIndex >0 ){
                    currentId = pageIndex* 10;
                }
            }
            buyIdGroup = new uint256[](len);
            unchecked {
                for(uint256 i; i<len; i++){
                    buyIdGroup[i] = currentId;
                    currentId++;
                }
            }
        }
    }

    /**
     * @notice  .
     * @dev     .
     * @param   marketId  .
     * @param   user  .
     * @param   pageIndex  .
     */
    function indexUserSellIds(
        uint256 marketId, 
        address user, 
        uint16 pageIndex
    ) external view returns(uint256[] memory sellIdGroup) {
        uint256 len;
        uint256 currentId;
        address market = _getMarket(marketId);
        uint256 sellIdsLength = IDustFlowCore(market).getUserSellIdsLength(user);
        require(pageIndex <= sellIdsLength / 10, "Page index overflow");
        if(sellIdsLength >0 ){
            if(sellIdsLength <= 10){
                len = sellIdsLength;
            }else {
                if(sellIdsLength % 10 == 0){
                    len = 10;
                }else {
                    len = sellIdsLength % 10;
                }
                if(pageIndex >0 ){
                    currentId = pageIndex* 10;
                }
            }
        }
        sellIdGroup = new uint256[](len);
        unchecked {
            for(uint256 i; i<len; i++){
                sellIdGroup[i] = currentId;
                currentId++;
            }
        }
    }

    /**
     * @notice  .
     * @dev     .Obtain the current status of the order
     * @param   marketId  .
     * @param   orderId  .
     */
    function getOrderState(
        uint256 marketId, 
        uint256 orderId
    ) public view returns(OrderCurrentState state) {
        IDustFlowCore.OrderInfo memory newOrderInfo = getOrderInfo(marketId, orderId);
        uint256 endTime = _getEndTime(marketId); 
        if(endTime == 0 || block.timestamp <= endTime){
            if(
                newOrderInfo.state == IDustFlowCore.OrderState.buying || 
                newOrderInfo.state == IDustFlowCore.OrderState.selling
            ){
                state = OrderCurrentState.trading;
            }else if(newOrderInfo.state == IDustFlowCore.OrderState.found){
                state = OrderCurrentState.found;
            }else if(newOrderInfo.state == IDustFlowCore.OrderState.done){
                state = OrderCurrentState.done;
            }
            else{
                state = OrderCurrentState.inexistence;
            }
        }else{
            if(
                newOrderInfo.state == IDustFlowCore.OrderState.buying || 
                newOrderInfo.state == IDustFlowCore.OrderState.selling
            ){
                state = OrderCurrentState.refund;
            }else if(
                newOrderInfo.state == IDustFlowCore.OrderState.found
            ){
                state = OrderCurrentState.absenteeism;
            }else if(
                newOrderInfo.state == IDustFlowCore.OrderState.done
            ){
                state = OrderCurrentState.done;
            }else {
                state = OrderCurrentState.inexistence;
            }
        }
    }
    
    /**
     * @notice  .
     * @dev     .
     * @param   token  .
     */
    function getTokenDecimals(address token) public view returns(uint8) {
        return IERC20Metadata(token).decimals();
    }

    /**
     * @notice  .
     * @dev     .
     * @param   token  .
     * @param   user  .
     */
    function getUserTokenBalance(address token, address user) public view returns(uint256) {
        return IERC20(token).balanceOf(user);
    }

    /**
     * @notice  .
     * @dev     .
     * @param   marketId  .
     * @param   total  .
     */
    function getFee(
        uint256 marketId,
        uint256 total
    ) public view returns(uint256 _thisFee){
        address collateral = IGovernance(governance).getMarketConfig(marketId).collateral;
        uint8 decimals = getTokenDecimals(collateral);
        _thisFee = DustFlowLibrary._fee(
            total,
            decimals
        );
    }

    /**
     * @notice  .
     * @dev     .The quantity and cost of the collateral to be pledged to obtain the matching order
     * @param   orderType  .
     * @param   price  .
     * @param   marketId  .
     * @param   orderIds  .
     */
    function getTradeAmount(
        IDustFlowCore.OrderType orderType,
        uint64 price,
        uint256 marketId,
        uint256[] calldata orderIds
    ) external view returns(
        uint256 fee,
        uint256 collateralTokenAmount,
        uint256 waitTokenAmount
    ) {
        if(block.timestamp + 12 hours < _getEndTime(marketId)){
            unchecked{
                for(uint256 i; i<orderIds.length; i++){
                    IDustFlowCore.OrderInfo memory newOrderInfo = getOrderInfo(marketId, orderIds[i]);
                    uint64 currentPrice = newOrderInfo.price;
                    uint64 remainAmount;
                    //buy
                    if(orderType == IDustFlowCore.OrderType.buy){
                        if(newOrderInfo.state == IDustFlowCore.OrderState.selling){
                            if(currentPrice <= price){
                                remainAmount = newOrderInfo.amount - newOrderInfo.doneAmount;
                                if(remainAmount > 0){
                                    fee += getFee(marketId, remainAmount);
                                }
                            }
                        }
                    }else{
                        //sell
                        if(newOrderInfo.state == IDustFlowCore.OrderState.buying){
                            if(currentPrice >= price){
                                remainAmount = newOrderInfo.amount - newOrderInfo.doneAmount;
                            }
                        }
                    }
                    if(remainAmount> 0){   
                        waitTokenAmount += remainAmount;
                        collateralTokenAmount += _getCurrentTotalCollateral(
                            newOrderInfo.price, 
                            remainAmount
                        );
                    }
                }
            }
        }
        if(collateralTokenAmount > 0){
            if(orderType == IDustFlowCore.OrderType.buy){
                collateralTokenAmount = collateralTokenAmount * 2 - fee;
            }
        }
            
    }

    /**
     * @notice  .
     * @dev     .The array of cancelled orders can receive collateral and fees
     * @param   marketId  .
     * @param   user  .
     * @param   orderIds  .
     */
    function getCancelAmount(
        uint256 marketId,
        address user,
        uint256[] calldata orderIds
    ) external view returns(
        uint256 fee,
        uint256 collateralTokenAmount
    ) { 
        if(block.timestamp + 12 hours < _getEndTime(marketId)){
            unchecked {
                for(uint256 i; i<orderIds.length; i++){
                    IDustFlowCore.OrderInfo memory newOrderInfo = getOrderInfo(marketId, orderIds[i]);
                    if(user == newOrderInfo.creator){
                        if(
                            newOrderInfo.state == IDustFlowCore.OrderState.buying || 
                            newOrderInfo.state == IDustFlowCore.OrderState.selling
                        ){
                            uint64 remainAmount = newOrderInfo.amount - newOrderInfo.doneAmount;
                            if(remainAmount >0){
                                collateralTokenAmount += _getCurrentTotalCollateral(
                                    newOrderInfo.price, 
                                    remainAmount);
                            }
                            newOrderInfo.state = IDustFlowCore.OrderState.fail;
                        }
                    }
                }
            }
            fee = collateralTokenAmount * 5 / 1000;
            collateralTokenAmount = collateralTokenAmount - fee;
        }
    }

    /**
     * @notice  .
     * @dev     .How many target tokens does the seller need to stake to obtain the completed order
     * @param   marketId  .
     * @param   user  .
     * @param   orderIds  .
     * @return  waitTokenAmount  .
     */
    function getDepositeAmount(
        uint256 marketId,
        address user,
        uint256[] calldata orderIds
    ) external view returns (
        uint256 waitTokenAmount
    ){  
        unchecked {
            for(uint256 i; i< orderIds.length; i++){
                IDustFlowCore.OrderInfo memory newOrderInfo = getOrderInfo(marketId, orderIds[i]);
                if(user == newOrderInfo.creator){
                    if(
                        newOrderInfo.orderType == IDustFlowCore.OrderType.sell && 
                        newOrderInfo.state == IDustFlowCore.OrderState.found
                    ){
                        waitTokenAmount += _getCurrentTotalTargetAmount(
                            marketId,
                            newOrderInfo.price,
                            newOrderInfo.doneAmount
                        );
                    }
                }else if(user == newOrderInfo.trader){
                    if(
                        newOrderInfo.orderType == IDustFlowCore.OrderType.buy && 
                        newOrderInfo.state == IDustFlowCore.OrderState.found
                    ){
                        waitTokenAmount += _getCurrentTotalTargetAmount(
                            marketId,
                            newOrderInfo.price,
                            newOrderInfo.doneAmount
                        );
                    }
                }
            }
        }
    }

    /**
     * @notice  .
     * @dev     .The amount of refund received
     * @param   marketId  .
     * @param   user  .
     * @param   orderIds  .
     */
    function getRefundAmount(
        uint256 marketId,
        address user,
        uint256[] calldata orderIds
    ) external view returns(uint256 collateralTokenAmount) {
        if(block.timestamp > _getEndTime(marketId) && _getEndTime(marketId) != 0){
            unchecked {
                for(uint256 i; i<orderIds.length; i++){
                    IDustFlowCore.OrderInfo memory newOrderInfo = getOrderInfo(marketId, orderIds[i]);
                    if(user == newOrderInfo.creator){
                        if(
                            newOrderInfo.state == IDustFlowCore.OrderState.buying || 
                            newOrderInfo.state == IDustFlowCore.OrderState.selling
                        ){
                            collateralTokenAmount += _getCurrentTotalCollateral(
                                newOrderInfo.price, 
                                newOrderInfo.amount - newOrderInfo.doneAmount
                            );
                        }
                    }
                }
            }
        }
    }

    /**
     * @notice  .
     * @dev     .Obtain the withdrawable quantity of the completed order
     * @param   marketId  .
     * @param   user  .
     * @param   orderIds  .
     */
    function getDoneOrderWithdrawAmount(
        uint256 marketId,
        address user,
        uint256[] calldata orderIds
    ) external view returns(
        uint256 fee,
        uint256 collateralTokenAmount,
        uint256 waitTokenAmount
    ){
        if(block.timestamp > _getEndTime(marketId)){
            unchecked {
                for(uint256 i; i< orderIds.length; i++){
                    IDustFlowCore.OrderInfo memory newOrderInfo = getOrderInfo(marketId, orderIds[i]);
                    uint256 thisTotalAmount = _getCurrentTotalCollateral(
                        newOrderInfo.price, 
                        newOrderInfo.doneAmount
                    );
                    if(user == newOrderInfo.creator){
                        if(
                            newOrderInfo.orderType == IDustFlowCore.OrderType.buy && 
                            newOrderInfo.state == IDustFlowCore.OrderState.done
                        ){
                            if(newOrderInfo.creatorWithdrawState == ZEROBYTES1){
                                waitTokenAmount += _getCurrentTotalTargetAmount(
                                    marketId,
                                    newOrderInfo.price,
                                    newOrderInfo.doneAmount
                                );
                            }
                        } else if(
                            newOrderInfo.orderType == IDustFlowCore.OrderType.sell && 
                            newOrderInfo.state == IDustFlowCore.OrderState.done
                        ){
                            if(newOrderInfo.creatorWithdrawState == ZEROBYTES1){
                                collateralTokenAmount += thisTotalAmount;
                                fee += getFee(marketId, thisTotalAmount);
                            }
                        }
                    }else if (user == newOrderInfo.trader){
                        if(
                            newOrderInfo.orderType == IDustFlowCore.OrderType.buy && 
                            newOrderInfo.state == IDustFlowCore.OrderState.done
                        ){
                            if(newOrderInfo.traderWithdrawState == ZEROBYTES1){
                                collateralTokenAmount += thisTotalAmount;
                                fee += getFee(marketId, thisTotalAmount);
                            }
                        } else if(
                            newOrderInfo.orderType == IDustFlowCore.OrderType.sell && 
                            newOrderInfo.state == IDustFlowCore.OrderState.done
                        ){
                            if(newOrderInfo.traderWithdrawState == ZEROBYTES1){
                                waitTokenAmount += _getCurrentTotalTargetAmount(
                                    marketId,
                                    newOrderInfo.price,
                                    newOrderInfo.doneAmount
                                );
                            }
                        }
                    }else {
                        revert("Invalid user");
                    }
                }
            }
        }
        collateralTokenAmount = collateralTokenAmount * 2 - fee;
    }

    /**
     * @notice  .
     * @dev     .Obtain the quantity that can be withdrawn from the defaulted order
     * @param   marketId  .
     * @param   user  .
     * @param   orderIds  .
     * @return  fee  .
     * @return  collateralTokenAmount  .
     */
    function getLiquidatedDamages(
        uint256 marketId,
        address user,
        uint256[] calldata orderIds
    ) external view returns (
        uint256 fee,
        uint256 collateralTokenAmount
    ){
        if(block.timestamp > _getEndTime(marketId)){
            unchecked {
                for(uint256 i; i< orderIds.length; i++){
                    IDustFlowCore.OrderInfo memory newOrderInfo = getOrderInfo(marketId, orderIds[i]);
                    uint256 thisTotalAmount = _getCurrentTotalCollateral(
                        newOrderInfo.price, 
                        newOrderInfo.doneAmount
                    );
                    if(user == newOrderInfo.creator){
                        if(newOrderInfo.state == IDustFlowCore.OrderState.found){
                            if(newOrderInfo.orderType == IDustFlowCore.OrderType.buy){}
                        }
                    }else if(user == newOrderInfo.trader){
                        if(newOrderInfo.state == IDustFlowCore.OrderState.found){
                            if(newOrderInfo.orderType == IDustFlowCore.OrderType.sell){}
                        }
                    }else{
                        revert("Invalid user");
                    }
                    collateralTokenAmount += thisTotalAmount;
                    fee += getFee(marketId, thisTotalAmount);
                }
            }
        }
        collateralTokenAmount = collateralTokenAmount * 2 - fee;
    }

    /**
     * @notice  .Each page can accommodate a maximum of 10 data points
     * @dev     .Obtain the array of stream payment information sent or received by the user
     * @param   state  .
     * @param   dust  .
     * @param   user  .
     * @param   pageIndex  .
     * @return  dustFlowInfoGroup  .
     * @return  receiveAmountGroup  .
     */
    function indexUserSenderFlowInfos(
        IDustCore.UserFlowState state,
        address dust,
        address user,
        uint256 pageIndex
    ) external view returns (
        IDustCore.DustFlowInfo[] memory dustFlowInfoGroup,
        uint128[] memory receiveAmountGroup
    ) {
        uint256 flowIdsLength = IDustCore(dust).getUserFlowIdsLength(user, state);
        if (flowIdsLength > 0) {
            uint256 len;
            uint256 idIndex;
            uint256 currentUserFlowId;
            require(pageIndex <= flowIdsLength / 10, "PageIndex overflow");
            if (flowIdsLength <= 10) {
                len = flowIdsLength;
            } else {
                if (flowIdsLength % 10 == 0) {
                    len = 10;
                } else {
                    len = flowIdsLength % 10;
                }
                if (pageIndex > 0) {
                    idIndex = pageIndex * 10;
                    currentUserFlowId = IDustCore(dust).getUserFlowId(user, state, idIndex);
                }
            }
            dustFlowInfoGroup = new IDustCore.DustFlowInfo[](len);
            receiveAmountGroup = new uint128[](len);
            unchecked {
                for (uint256 i; i < len; i++) {
                    dustFlowInfoGroup[i] = IDustCore(dust).getDustFlowInfo(currentUserFlowId);
                    receiveAmountGroup[i] = IDustCore(dust).getReceiveAmount(currentUserFlowId);
                    currentUserFlowId++;
                }
            }
        }
    }

    function _getMarket(uint256 marketId) private view returns(address) {
        return IDustFlowFactory(dustFlowFactory).getMarketInfo(marketId).market;
    }

    function _getEndTime(uint256 marketId) private view returns(uint256) {
        return IGovernance(governance).getMarketConfig(marketId).endTime;
    }

    function _tokenDecimals(address token) private view returns(uint8) {
        return IERC20Metadata(token).decimals();
    }

    function _getMarketConfig(uint256 _marketId) private view returns(IGovernance.MarketConfig memory) {
        return IGovernance(governance).getMarketConfig(_marketId);
    }

    function _getCurrentTotalCollateral(uint64 _price , uint64 _amount) private pure returns(uint256 _totalCollateral) {
        _totalCollateral = DustFlowLibrary._getTotalCollateral(
            _price,
            _amount
        );
    }

    function _getCurrentTotalTargetAmount(uint256 _marketId, uint64 _price , uint64 _amount) private view returns(uint256 _totalTargetAmount) {
        address targetToken  =  _getMarketConfig(_marketId).waitToken;
        address collateral =  _getMarketConfig(_marketId).collateral;
        uint8 targetTokenDecimals = _tokenDecimals(targetToken);
        uint8 collateralDecimals = _tokenDecimals(collateral);
        _totalTargetAmount = DustFlowLibrary._getTargetTokenAmount(
            targetTokenDecimals,
            collateralDecimals,
            _price,
            _amount
        );
    }

}