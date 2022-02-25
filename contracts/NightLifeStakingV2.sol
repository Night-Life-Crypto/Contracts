// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract UserRewards is Context, Ownable{
   
    address public lpToken;
    address public rewardToken;
    uint256 public TOTALUSERREWARDS = 0;
	address public NLIFEWallet;

    struct USERREWARD{
        uint256 userReward;     
    }

    struct STAKE {
        uint256 amount;
        uint256 lastUpdatedAt;
    }

    event Stake(address _staker, uint256 amount);
    event Unstake(address _staker, uint256 amount);
    event Withdraw(address _staker, uint256 amount);

    mapping(address => STAKE) public _stakeInfo;
    mapping(address => USERREWARD) public _userRewardsDetails;
    address[] public _stakers;

    constructor(address _rewardToken) public {
        rewardToken = _rewardToken;
        NLIFEWallet = msg.sender;
    }   

    function updateNLIFEWallet(address _newAddr) public onlyOwner {
        require(_newAddr != address(0), "Avoid Zero Address");
        NLIFEWallet = _newAddr;
    }

   function getUserReward() public view returns (uint256) {
       require(_userRewardsDetails[msg.sender].userReward > 0, "User is not staker.");
       USERREWARD memory findUser = _userRewardsDetails[msg.sender];
       return findUser.userReward;
   }


   function totalRewards() public view returns(uint256){
       return getCurrentNLIFEBalance() - totalUserRewards();
   }

    function totalUserRewards() public view returns (uint256){
        uint256 sumRewards = 0;
        uint arrayLength = _stakers.length;
        for(uint i=0 ;i< arrayLength; i++){
           sumRewards += _userRewardsDetails[_stakers[i]].userReward;
        }              
        return sumRewards;
    }
    
    function totalStakeAmount() public view returns (uint256){
        uint256 sumStakers = 0;
        uint arrayLength = _stakers.length;
        for(uint i=0 ;i< arrayLength; i++){
           sumStakers += _stakeInfo[_stakers[i]].amount;
        }              
        return sumStakers;
    }

   // Calculate Claim Reward when user claims
    function claimUserRewardsV2(uint256 amount, address staker) public{      
        USERREWARD memory userRew = _userRewardsDetails[staker];
        STAKE memory stakerUser = _stakeInfo[staker];
        uint partitionStakeAmount = SafeMath.div(stakerUser.amount, totalStakeAmount());
        uint totalRewards = SafeMath.sub(getCurrentNLIFEBalance(),userRew.userReward); 
        uint userIncrementReward = SafeMath.mul(totalRewards, partitionStakeAmount);
        uint newUserIncrementReward = SafeMath.mul(amount,partitionStakeAmount);
        _userRewardsDetails[staker].userReward = SafeMath.add(newUserIncrementReward, userRew.userReward);   
    }

    // Total Wallet Balance
    function getCurrentNLIFEBalance() public view returns (uint256){
        // return IERC20(NLIFEWallet).balanceOf(address(this));
        // only for testing 
        uint256 balance = 10000;
        balance;
    }


    function isStakeHolder(address _account) public view returns (bool) {
        return _stakeInfo[_account].amount > 0;
    }

    function setLPToken(address _lpToken) public onlyOwner {
        lpToken = _lpToken;
    }

    function setRewardToken(address _rewardToken) public onlyOwner {
        rewardToken = _rewardToken;
    }

    function rewardTokenAddr() public view returns (address) {
        return rewardToken;
    }

    function dummySetStaker(address staker, uint256 amount) public onlyOwner{
       _stakers.push(staker);
       _stakeInfo[staker].amount = amount;
    }

    function rewardOf(address _staker) public view returns (uint256) {
        STAKE memory _stakeDetail = _stakeInfo[_staker];

        uint256 _rewards = totalRewards();
        uint256 _singlePart =
            SafeMath.mul(_stakeDetail.amount, SafeMath.sub(block.timestamp, _stakeDetail.lastUpdatedAt));

        uint256 _totalPart;

        for (uint256 i = 0; i < _stakers.length - 1; i++) {
            STAKE memory _singleStake = _stakeInfo[_stakers[i]];
            _totalPart =  SafeMath.add(_totalPart, (SafeMath.mul(_singleStake.amount, SafeMath.sub(block.timestamp, _singleStake.lastUpdatedAt))));
        }

        if (_totalPart == 0) return 0;

        return SafeMath.div(SafeMath.mul(_rewards, _singlePart),_totalPart);
    }

    function stake(uint256 _amount) public {
        IERC20(lpToken).transfer(address(this), _amount);
        STAKE storage _stake = _stakeInfo[_msgSender()];

        if (_stake.amount > 0) {
            uint256 reward = rewardOf(_msgSender());
            _stake.lastUpdatedAt = block.timestamp;
            _stake.amount = SafeMath.add(_stake.amount, _amount);
            IERC20(rewardToken).transfer(_msgSender(), reward);
            emit Withdraw(_msgSender(), reward);
        } else {
            _stake.lastUpdatedAt = block.timestamp;
            _stake.amount = _amount;
            _stakers.push(_msgSender());
        }
        emit Stake(_msgSender(), _amount);
    }

    function unstake() public {
        require(_stakeInfo[_msgSender()].amount > 0, "Not staking");

        STAKE storage _stake = _stakeInfo[_msgSender()];
        uint256 reward = rewardOf(_msgSender());
        uint256 amount = _stake.amount;
        _stake.amount = 0;
        _stake.lastUpdatedAt = block.timestamp;

        IERC20(rewardToken).transfer(_msgSender(), reward);
        for (uint256 i = 0; i < _stakers.length; i++) {
            if (_stakers[i] == _msgSender()) {
                _stakers[i] = _stakers[_stakers.length - 1];
                _stakers.pop();
                break;
            }
        }

        uint256 fee = SafeMath.div(amount ,100);
        uint256 _amount = SafeMath.sub(amount, fee);
        IERC20(lpToken).transfer(_msgSender(), _amount);
        IERC20(lpToken).transfer(NLIFEWallet, fee);
        emit Unstake(_msgSender(), amount);
    }

    function claimReward() public {
        STAKE storage _stake = _stakeInfo[_msgSender()];
        uint256 reward = rewardOf(_msgSender());
        _stake.lastUpdatedAt = block.timestamp;
        for(uint i = 0; i < _stakers.length - 1; i++){
           claimUserRewardsV2(0, _stakers[i]);
        }
        IERC20(rewardToken).transfer(_msgSender(), reward);
        emit Withdraw(_msgSender(), reward);
    }
  }