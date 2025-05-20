// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

library DustFlowLibrary {

    function _getTotalCollateral(
        uint64 price,
        uint64 amount
    ) internal pure returns (uint256 totalCollateral){
        totalCollateral = price * amount/ (10 ** 6);
    }

    function _getTargetTokenAmount(
        uint8 _targetDecimals,
        uint8 _collateralDecimals,
        uint64 price,
        uint64 amount
    ) internal pure returns (uint256 targetTokenAmount) {
        if(_collateralDecimals > _targetDecimals){
            targetTokenAmount = price * amount / (10 ** 6) / 10 ** (_collateralDecimals - _targetDecimals);
        }else if(_collateralDecimals < _targetDecimals){
            targetTokenAmount = price * amount / (10 ** 6) * 10 ** (_targetDecimals - _collateralDecimals);
        }else{
                targetTokenAmount = price * amount / (10 ** 6);
        }
    }

    function _fee(
        uint256 total,
        uint8 tokenDecimals
    ) internal pure returns (uint256 _thisFee) {
        if (
            total >= 10 * 10 ** tokenDecimals &&
            total < 1000 * 10 ** tokenDecimals
        ) {
            _thisFee = total / 100;
        } else if (
            total >= 1000 * 10 ** tokenDecimals &&
            total < 10000 * 10 ** tokenDecimals
        ) {
            _thisFee = (total / 1000) * 80;
        } else if (total >= 10000 * 10 ** tokenDecimals) {
            _thisFee = (total / 1000) * 50;
        } else {
            
        }
    }

    function _getCurrentRevenue(
        uint256 _userShare, 
        uint256 _stageTotalShare, 
        uint256 _stageReserve1Revenue,
        uint256 _capture
    ) internal pure returns(uint256){
        uint256 _revenue;
        if(_userShare > 0 && _stageTotalShare > 0 && _stageReserve1Revenue > 0){
            _revenue = _userShare * _stageReserve1Revenue/ _stageTotalShare;
        }
        _revenue = _revenue + _capture;
        return _revenue;
    }
}
