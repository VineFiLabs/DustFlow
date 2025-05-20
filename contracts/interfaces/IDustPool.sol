// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IDustPool{

    enum Way{inject, exit}

    struct UserInfo{
        uint256 dustAmount;
        uint256 shareAmount;
        uint256 captureAmount;
        uint256 startAmount;
        uint256 startExtractedAmount;
        uint256 startBurnShare;
        uint256 number;
    }


    event ChangeOwner(address older, address newer);
    event ChangeManager(address older, address newer);
    event Deposite(address user, uint256 thisShare, uint256 amount);
    event Withdraw(address user, uint256 amount);

}

