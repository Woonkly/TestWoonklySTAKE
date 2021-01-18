// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;


interface IWStaked{
    function NotifyAddStake(address account, uint256 amount) external returns(bool);
    function NotifyWithdrawFunds(address account, uint256 amount) external returns(uint256);
    function NotifyActiveChanged(bool activeStatus)  external returns(bool);
}