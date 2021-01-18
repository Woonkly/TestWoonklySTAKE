// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;


interface IInvestable{
    function getFreezeCount() external returns(uint256) ;
    function getLastIndexFreezes() external returns(uint256);     
    function FreezeExist(address account) external returns(bool);
    function FreezeIndexExist(uint256 index) external returns(bool);
    function newFreeze(address account,uint256 amount,uint256 date ) external returns(uint256);
    function removeFreeze(address account) external;
    function getFreeze(address account) external returns( uint256 , uint256 , uint256 );
    function getFreezeByIndex(uint256 index) external returns( uint256 , uint256 , uint256 );
    function getAllFreeze() external returns(uint256[] memory, address[] memory ,uint256[] memory , uint256[] memory , uint256[] memory );
    function updateFund(address account,uint256 withdraw) external  returns(bool);
    function canWithdrawFunds(address account,uint256 withdraw,uint256 currentFund) external returns(bool);
    function howMuchCanWithdraw(address account,uint256 currentFund) external returns(uint256);
        
}