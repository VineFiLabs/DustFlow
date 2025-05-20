// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IDust{
    function depositeMint(address receiver, uint256 amount) external returns(bool);
    function burn(uint256 amount) external returns(bool);
}

