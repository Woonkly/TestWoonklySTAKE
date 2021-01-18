// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./../contracts/math/SafeMath.sol";
import "./../contracts/token/ERC20/ERC20.sol";
import "./../contracts/utils/ReentrancyGuard.sol";

import "./../utils/Utils.sol";

import "./Pausabled.sol";
import "./Erc20Manager.sol";
import "./StakeManager.sol";
import "./IWStaked.sol";
import "./IInvestiable.sol";


contract WOOPStake is Owners,StakeManager,Pausabled,Erc20Manager,ReentrancyGuard {

  using SafeMath for uint256;
  
  address internal _remainder;
  //uint256 internal _fractionUnit;
  address internal _woopERC20;
  uint256 internal _distributedCOIN;
  IInvestable internal  _inv;
  uint256 _factor;
  
  
  mapping (address => mapping (address => uint256)) private _rewards;
  mapping (address => uint256) private _rewardsCOIN;
  mapping (address => uint256) private _distributeds;
  

  constructor(string memory name, string memory symbol  ,  address remAcc, address woopERC20,address inv) 
        StakeManager(name,symbol)
        public 
        {
        _paused=false;
        _remainder=remAcc;
        //_fractionUnit=1000000000000000000000;
         _factor=10**8;
        _distributedCOIN=0;
        _woopERC20=woopERC20;
        _inv=IInvestable(inv) ;
        
  
  }
  
    event RewardedCOIN( address account, uint256 reward);
    
    function _dorewardCOIN( address account, uint256 reward) internal  {

        require(account != address(0), "WO:0addr");

        _rewardsCOIN[account] = reward;
        emit RewardedCOIN( account, reward);
    }

    function rewardedCOIN( address account) public view  returns (uint256) {
        return _rewardsCOIN[account];
    }
  
    function _rewardCOIN( address account, uint256 amount) internal  returns (bool) {
        _dorewardCOIN( account, amount);
        return true;
    }

    function _increaseRewardsCOIN( address account, uint256 addedValue) internal returns (bool) {
        _dorewardCOIN(account, _rewardsCOIN[account].add(addedValue));
        return true;
    }

    function _decreaseRewardsCOIN( address account, uint256 subtractedValue) internal  returns (bool) {
        _dorewardCOIN( account, _rewardsCOIN[account].sub(subtractedValue, "WO:-0"));
        return true;
    }

  

    event Rewarded(address sc, address account, uint256 reward);
    
    function _doreward(address sc, address account, uint256 reward) internal  {
        require(sc != address(0), "WO:0addr");
        require(account != address(0), "WO:0addr");

        _rewards[sc][account] = reward;
        emit Rewarded(sc, account, reward);
    }

    function rewarded(address sc, address account) public view  returns (uint256) {
        return _rewards[sc][account];
    }

    function _reward(address sc, address account, uint256 amount) internal  returns (bool) {
        _doreward(sc, account, amount);
        return true;
    }

    function _increaseRewards(address sc, address account, uint256 addedValue) internal returns (bool) {
        _doreward(sc, account, _rewards[sc][account].add(addedValue));
        return true;
    }

    function _decreaseRewards(address sc, address account, uint256 subtractedValue) internal  returns (bool) {
        _doreward(sc, account, _rewards[sc][account].sub(subtractedValue, "WO:-0"));
        return true;
    }





    event CoinReceived(uint256 coins);
    
    receive() external payable {
            // React to receiving ether
            _processRewardCOIN( msg.value);
            emit CoinReceived(msg.value);
    }
        

    fallback()  external payable {
        //emit CoinReceived(msg.value); 
        
    }
  
    function getMyCoinBalance() public view returns(uint256){
            address payable self = address(this);
            uint256 bal =  self.balance;    
            return bal;
    }
    
    function getMyTokensBalance(address sc) public view returns(uint256){
        IERC20 _token = IERC20(sc);
        return _token.balanceOf(address(this));
    }



    function getTokensBalanceOf(address sc,address account)public view returns(uint256){
        IERC20 _token = IERC20(sc);
        return _token.balanceOf(account);
    }

    modifier IhaveEnoughTokens(address sc,uint256 token_amount) {
        uint256 amount=getMyTokensBalance(sc);
        require( token_amount <= amount ,"-tk" );
        _;
    }
  
  
    modifier IhaveEnoughCoins(uint256 coins) {
        uint256 amount=getMyCoinBalance();
        require( coins <= amount ,"-coin" );
        _;
    }


    modifier hasApprovedTokens(address sc,address sender, uint256 token_amount) {
        IERC20 _token = IERC20(sc);
        require(  _token.allowance(sender,address(this)) >= token_amount , "!aptk"); //sender != address(0) &&
        _;
    }


    function addErc20STK(address sc) public  onlyIsInOwners  returns(bool){
        newERC20(sc );
        return true;
    }

    function removeErc20STK(address sc) public  onlyIsInOwners  returns(bool){
        removeERC20(sc );
        return true;
    }
    
    function setFactor(uint256 newf) onlyIsInOwners public {
        require(newf <= 10**9,">lim" );
        _factor=newf;
    }
    
    function  getFactor() public view returns(uint256){
        return  _factor;
    }

    function getfractionUnit() public view returns(uint256){
        return (10**9) * (10**18)  / _factor;
    }
     



    function setInv(address inv) onlyIsInOwners public {
        _inv=IInvestable(inv) ;
    }
    
    function  getInv() public view returns(address){
        return  address(_inv);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {

        require(_inv.canWithdrawFunds(sender,amount,balanceOf(sender)),"WO:!i");
        super._transfer(sender,recipient,amount);
        _inv.updateFund(sender,amount);
    }






/*
    event FractionUnitChanged(uint256 old, uint256 newf);
    function setFractionUnit(uint256 newf) public onlyIsInOwners returns(bool){

        uint256 old=_fractionUnit;
        _fractionUnit=newf;
        emit FractionUnitChanged(old,newf);
        return true;
    }

*/









    function getDistributed(address sc) public view returns(uint256){
        return _distributeds[sc];
    }
    event DistributedReseted(address sc,uint256 old);
    function resetDistributed(address sc) public onlyIsInOwners returns(bool){

        uint256 old=_distributeds[sc];
        _distributeds[sc]=0;
        emit DistributedReseted(sc,old);
        return true;
    }


    function getDistributedCOIN() public view returns(uint256){
        return _distributedCOIN;
    }

    event DistributedCOINReseted(uint256 old);
    function resetDistributedCOIN() public onlyIsInOwners returns(bool){

        uint256 old=_distributedCOIN;
        _distributedCOIN=0;
        emit DistributedCOINReseted(old);
        return true;
    }





    function getRemaninderAcc() public view returns(address){
        return _remainder;
    }

    event RemaninderAccChanged(address old,address newr);
    function setRemaniderAcc(address newr) public onlyIsInOwners returns(bool){
        address old=_remainder;
        _remainder=newr;
        emit RemaninderAccChanged(old,newr);
        return true;
    }





    function getERC20WOOP() public view returns(address){
        return _woopERC20;
    }
    
    
    event ERC20WOOPChanged(address old,address newr);
    function setERC20WOOP(address newr) public onlyIsInOwners returns(bool){
        address old=_woopERC20;
        _woopERC20=newr;
        emit ERC20WOOPChanged(old,newr);
        return true;
    }






    function setMyCompoundStatus(bool status) public onlyStakeExist(_msgSender()) returns(bool){
        setAutoCompound(_msgSender(), status);
       if(status==true) _compoundReward( _msgSender(), rewarded( _woopERC20, _msgSender() ) );
        return true;
    }






    function addStake( uint256 amount) Active hasApprovedTokens( _woopERC20, _msgSender(), amount)  public returns(bool){

        require(amount >= getfractionUnit(),"WO:-am" );

        IERC20 _token = IERC20(_woopERC20);
        
        require(_token.transferFrom(_msgSender(),address(this), amount),"WO:-etf");
        
        require(  _addStake(   _msgSender(), amount ) , "WO:eas");
        
        return true;
    }
    


    function SYNCaddStake(address account, uint256 amount) Active onlyIsInOwners   public returns(bool){
        require(  _addStake(   account, amount ) , "WO:eas");
        return true;
    }
  
    
    
    function _addStake(address account, uint256 amount) Active  internal returns(bool){

        if(!StakeExist(account)){
            //NEW
                        
            newStake(account, amount );
            
            
        }else{
            //has funds
            
            addToStake(account, amount);
            
        }
        
        return true;
        
    }
    





    
    event WithdrawFunds( address account,uint256 amount,uint256 remainder);

    function _withdrawFunds( address account, uint256 amount) Active onlyStakeExist(account) internal returns(uint256){
        
        uint256 fund;
        bool autoC;
        
        (fund,autoC)=getStake(account);
         
        require(amount <= fund,"WO:eef");    

     //   require( amount <= getMyTokensBalance() ,"I do not have enough tokens " );        

        uint256 remainder=fund.sub(amount);
        
        if(remainder==0){
        
            removeStake(account);

        }else{
            
            renewStake(account, remainder);

        }

        WithdrawFunds(account, amount,remainder);
        
        return amount;
    }





    
    function withdrawFunds( uint256 amount) Active onlyStakeExist(_msgSender())  public returns(bool){
        require(_inv.canWithdrawFunds(_msgSender(),amount,balanceOf(_msgSender())),"WO:!i");
        
        uint256 fund;
        bool autoC;
        IERC20 _token = IERC20(_woopERC20);
        
        (fund,autoC)=getStake(_msgSender());

        require(_token.transfer(_msgSender(), amount),"WO:ewf");
        _withdrawFunds(_msgSender(),  amount);
        
        _inv.updateFund(_msgSender(),amount);
        return true;
    }
    


    function SYNCwithdrawFunds(address account, uint256 amount) Active onlyIsInOwners  public returns(bool){
        
        uint256 fund;
        bool autoC;

        (fund,autoC)=getStake(account);
        _withdrawFunds(_msgSender(),  amount);
        return true;
    }
    



    event RewardWithdrawed(address sc, address account,uint256 amount,uint256 remainder);

    function _withdrawReward(address sc,address account, uint256 amount) Active internal returns(uint256){

        IERC20 _token = IERC20(sc);

        uint256 rew=rewarded( sc, account);
         
         require(amount <= rew,"WO:amew");    

        require( amount <= getMyTokensBalance(sc) ,"WO:-tk" );        
        
        require(_token.transfer(account, amount));
        
        uint256 remainder = rew.sub(amount);
        
        if(remainder==0){
            _doreward(sc, account, 0);
        }else{
            require(_decreaseRewards( sc,  account, remainder),"WO:e--");    
        }
        

        
        
        RewardWithdrawed(sc, account, amount,remainder);
        
        return amount;
    }


    event RewardToCompound(address account, uint256 amount);
    function _compoundReward(address account, uint256 amount) Active internal returns(uint256){

        //require(sc==_woopERC20,"woonklyPOS: _compoundReward Error only for WOOPS ");

        uint256 rew=rewarded( _woopERC20, account);
         
         require(amount <= rew,"WO: am>w");    

        require( amount <= getMyTokensBalance(_woopERC20) ,"WO:-tk" );        

        uint256 remainder = rew.sub(amount);
        
        if(remainder==0){
            _doreward(_woopERC20, account, 0);
        }else{
            require(_decreaseRewards( _woopERC20,  account, remainder),"WO:e--");    
        }
        
        addToStake(account, amount);
        
        
        RewardToCompound( account,  amount);
        
        return amount;
    }




    
    function WithdrawReward(address sc,uint256 amount) Active  public returns(bool){

        _withdrawReward(sc,  _msgSender(),  amount);

        return true;
    }

    function CompoundReward(uint256 amount) Active  public returns(bool){

        _compoundReward( _msgSender(), amount);

        return true;
    }






    event RewardCOINWithdrawed( address account,uint256 amount,uint256 remainder);

    function _withdrawRewardCOIN(address account, uint256 amount) Active internal returns(uint256){



        uint256 rew=rewardedCOIN( account);
         
         require(amount <= rew,"WO:am++");    

        require( amount <=  getMyCoinBalance()  ,"WO:tk-" );        
        
        
        address payable acc = address(uint160(address(account)));
        
        acc.transfer(amount);
        
        uint256 remainder = rew.sub(amount);
        
        if(remainder==0){
            _dorewardCOIN( account, 0);
        }else{
            require(_decreaseRewardsCOIN( account, remainder),"WO:e--");    
        }

        RewardCOINWithdrawed( account, amount,remainder);
        
        return amount;
    }
    

    function WithdrawRewardCOIN(uint256 amount) Active  public returns(bool){

        _withdrawRewardCOIN(  _msgSender(),  amount);

        return true;
    }

    


    function getCalcRewardAmount(address account,  uint256 amount) public view returns(uint256,uint256){
        
        if(!StakeExist(account)) return (0,0);
        
        //if(_fractionUnit<1) return (0,0);
        
        uint256 fund=0;
        bool autoC;
    
        (fund, autoC) = getStake(account);
        
        if(fund < getfractionUnit() ) return (0,0);

        uint256 factor=fund / getfractionUnit();
        
        if(factor < 1) return (0,0);
        
        uint256 remainder= fund.sub( factor.mul(getfractionUnit()) );
        
        uint256 woopsRewards=calcReward(amount,factor);
        
        if(woopsRewards<1) return (0,0);

         return (woopsRewards, remainder);
         
    }


   function calcReward(uint256 amount, uint256 factor) public view returns(uint256){
        
        return amount.mul(factor) / _factor;
       
   } 
   


/*
    modifier ValidTotalRewards(uint256 amount){
        uint256 total=calcTotalRewards(amount);
        require(calcTotalRewards(amount)<=amount,"WO:rew++");
        _;        
        
    }

*/
    modifier ProviderHasToken(address sc, uint256 amount){
        uint256 total=calcTotalRewards(amount);
        require( total <= getTokensBalanceOf(sc, _msgSender()) ,"WOO:tk-" );
        _;
        
    }
    
    /*
    modifier HasCoins( uint256 amount){
        uint256 total=calcTotalRewards(amount);
        require( total <=  getMyCoinBalance() ,"WOO:tk-" );
        _;
        
    }
    */

    modifier IhaveAprovedRewardTokens(address sc,uint256 amount) {
        uint256 total=calcTotalRewards(amount);
        IERC20 _token = IERC20(sc);
        require(  _token.allowance(_msgSender(),address(this)) >= total , "WOO:-apt");

        _;
    }




    function calcTotalRewards(uint256 amount) public view returns (uint256){
        uint256 remainder;
        uint256 woopsRewards;
        uint256 ind=0;
        uint256 total=0;

        for (uint32 i = 0; i < (_lastIndexStakes +1) ; i++) {
            Stake memory p= _Stakes[ i ];
            if(p.flag == 1 ){

                (woopsRewards, remainder) = getCalcRewardAmount(p.account, amount );
                if(woopsRewards>0){
                    total=total.add(woopsRewards);
                }
                ind++;
            }
        }
        return total;
    }





    event InsuficientRewardFund(address sc,address account);
    event NewLeftover(address sc,address account, uint256 leftover);


    struct processRewardInfo {
            uint256 remainder;
            uint256 woopsRewards;
            uint256 dealed;
            address me;
            bool resp;
    }        



    function _processReward_1(IERC20 _token,address account,  uint256 amount) internal returns(bool){

        require(_token.transferFrom(account,address(this), amount),"WO:etr"  );    
        return true;
    }
    

    function _processReward_2(address sc, uint256 amount) internal returns(uint256){
        
        processRewardInfo memory slot;
        
        for (uint32 i = 0; i < (_lastIndexStakes +1) ; i++) {
            Stake memory p= _Stakes[ i ];
            if(p.flag == 1 ){

                (slot.woopsRewards, slot.remainder) = getCalcRewardAmount(p.account, amount );
                if(slot.woopsRewards>0){

                    if(getAutoCompoundStatus(p.account) && sc==_woopERC20 ){
                        addToStake(p.account, slot.woopsRewards);
                    }else{
                         _increaseRewards( sc, p.account, slot.woopsRewards);
                    }

                    slot.dealed=slot.dealed.add(slot.woopsRewards);

                }else{
                    emit InsuficientRewardFund(sc, p.account);
                }

            }
        }//for
        
        _distributeds[sc]=_distributeds[sc].add(slot.dealed);
        
        return slot.dealed;
    }


//ValidTotalRewards(amount) 
    function processReward(address sc, uint256 amount) public 
         Active hasApprovedTokens(sc, _msgSender(), amount) ProviderHasToken(sc,amount)  
    returns(bool)  {
        
        if(!ERC20Exist( sc)){
            newERC20(sc );    
        }
        
        
        processRewardInfo memory slot;
        
        IERC20 _token = IERC20(sc);
        _processReward_1(_token,_msgSender(),  amount);

        slot.dealed=_processReward_2(sc,  amount);

        uint256 leftover=amount.sub(slot.dealed);
        if(leftover > 0){
            require(_token.transfer( _remainder, leftover) ,"WO:trf");  
            emit NewLeftover(sc, _remainder, leftover);
        }

        return true;
    }




    event InsuficientRewardFundCOIN(address account);
    event NewLeftoverCOIN(address account, uint256 leftover);


    function _processReward_2COIN( uint256 amount) internal  returns(uint256){
        
        processRewardInfo memory slot;
        
        for (uint32 i = 0; i < (_lastIndexStakes +1) ; i++) {
            Stake memory p= _Stakes[ i ];
            if(p.flag == 1 ){

                (slot.woopsRewards, slot.remainder) = getCalcRewardAmount(p.account, amount );
                
                if(slot.woopsRewards>0){

                    _increaseRewardsCOIN(  p.account, slot.woopsRewards);
                    
                    slot.dealed=slot.dealed.add(slot.woopsRewards);

                }else{
                    emit InsuficientRewardFundCOIN( p.account);
                }

            }
        }//for
        
        return slot.dealed;
    }


//HasCoins(amount) ValidTotalRewards(amount) 
    function _processRewardCOIN( uint256 amount) nonReentrant  internal
         Active    
    returns(bool)  {
        
        processRewardInfo memory slot;
        
        address payable nrem = address(uint160(address(_remainder)));
        
        slot.dealed=_processReward_2COIN(  amount);

        _distributedCOIN=_distributedCOIN.add(slot.dealed);
        
        uint256 leftover=amount.sub(slot.dealed);
        if(leftover > 0){
            nrem.transfer(leftover);
            emit NewLeftoverCOIN( _remainder, leftover);
        }

        return true;
    }






    event StakeClosed(uint256 csc, uint256 stakes, uint256 totFunds, uint256 totRew);
    
    function closeStakes() public onlyIsInOwners returns(bool){
        
        uint256 totRew=0;
        
        uint256 toSC=_lastIndexE20s +1;
        
        
        for (uint32 i = 0; i < (_lastIndexE20s +1) ; i++) {
            E20 memory p= _E20s[ i ];
            if(p.flag == 1 ){
                totRew=totRew.add( _withdrawAllrewards(p.sc) );
            }
        }

        totRew=totRew.add(_withdrawAllrewardsCOIN() );
        

        uint256 fund;
        bool autoC;
        uint256 funds=0;

        for (uint32 i = 0; i < (_lastIndexStakes +1) ; i++) {
            Stake memory p= _Stakes[ i ];
            if(p.flag == 1 ){
                
                (fund,autoC)=getStake(p.account);
                _withdrawFunds(p.account, fund);
                funds=funds.add(fund);
            }
        }
        
        setPause(true);
        removeAllStake();        
        

        StakeClosed(toSC, (_lastIndexStakes +1), funds, totRew);
        return true;
    }








                


    function _withdrawAllrewardsCOIN() SolvencyCOIN() internal returns(uint256){
        
        uint256 total=0;
        uint256 rew=0;
        
        for (uint32 i = 0; i < (_lastIndexStakes +1) ; i++) {
            Stake memory p= _Stakes[ i ];
            if(p.flag == 1 ){
                rew=rewardedCOIN( p.account);
                
                if(rew>0){
                    _withdrawRewardCOIN( p.account, rew);    
                    total=total.add(rew);
                }
                

            }
        }
        
        uint256 eth_reserve = address(this).balance;

        if(eth_reserve>0){
            address payable ow = address(uint160(_remainder));
            ow.transfer(eth_reserve);
        }

        return total;
    }
                



    function _withdrawAllrewards(address sc) Solvency(sc) internal returns(uint256){
        
        uint256 total=0;
        uint256 rew=0;
        
        for (uint32 i = 0; i < (_lastIndexStakes +1) ; i++) {
            Stake memory p= _Stakes[ i ];
            if(p.flag == 1 ){
                
                rew=rewarded( sc, p.account);
                
                if(rew>0){
                    _withdrawReward(sc, p.account, rew);    
                    total=total.add(rew);
                }
                
            }
        }
        
        IERC20 _token = IERC20(sc);
        
        uint256 token_reserve = _token.balanceOf(address(this));

        if(token_reserve>0) {
          require(_token.transfer(_remainder, token_reserve) ,"WO:trf");  
        } 
        
        return total;
    }


    modifier Solvency(address sc) {
        bool isSolvency;
        uint256 solvent;
        
        (isSolvency,solvent) = getSolvency(sc);
        
         require( isSolvency ,"WO:sol!");
        _;
    }


    modifier SolvencyCOIN() {
        bool isSolvency;
        uint256 solvent;
        
        (isSolvency,solvent) = getSolvencyCOIN();
        
         require( isSolvency ,"WO:sol!");
        _;
    }




    function getSolvencyCOIN() public view returns(bool,uint256){
        uint256 ind=0;
        uint256 funds=0;
        uint256 rews=0;
        uint256 rewsc=0;
        uint256 autos=0;

        (ind,funds,rews,rewsc,autos) = getStatistics(_woopERC20);
        
        uint256 coins=getMyCoinBalance();

        if(coins < rewsc ){
            return (false , rewsc-coins );
        }else{
            return (true , coins-rewsc );
        }
        
    }





    function getSolvency(address sc) public view returns(bool,uint256){
        uint256 ind=0;
        uint256 funds=0;
        uint256 rews=0;
        uint256 rewsc=0;
        uint256 autos=0;

        (ind,funds,rews,rewsc,autos) = getStatistics(sc);
        
        uint256 tokens=getMyTokensBalance(sc);
        
        uint256 tot=funds+rews;

        if(tokens < tot ){
            return (false , tot-tokens );
        }else{
            return (true , tokens-tot );
        }
        
    }



    function getStatistics(address sc) public view returns(uint256,uint256,uint256,uint256,uint256){

        uint256 ind=0;
        uint256 funds=0;
        uint256 rews=0;
        uint256 rewsCOIN=0;
        uint256 autocs=0;
        
        uint256 fund;
        bool autoC;
        
        for (uint32 i = 0; i < (_lastIndexStakes +1) ; i++) {
            Stake memory p= _Stakes[ i ];
            if(p.flag == 1 ){
                (fund,autoC)=getStake(p.account);
                
                if( sc==_woopERC20 ){
                    funds=funds.add(fund);
                }
                
                fund=rewarded( sc, p.account);
                
                rews=rews.add(fund);
 
                fund=rewardedCOIN(  p.account);
                
                rewsCOIN=rewsCOIN.add(fund);
                

                if(autoC){
                    autocs++;
                }
                ind++;
            }
        }
        return (ind,funds,rews,rewsCOIN,autocs);
    }


}