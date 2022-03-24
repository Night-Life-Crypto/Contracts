// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract UserRewards is Context, Ownable{
   
    address public _lpToken;
    address public _rewardToken;
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

    constructor(address rewardToken) public {
        _rewardToken = rewardToken;
        NLIFEWallet = _msgSender();
    }   

  
   function getUserReward(address _staker) public view returns (uint256) {
       require(_userRewardsDetails[_staker].userReward < 0, "User is not staker.");
       USERREWARD memory findUser = _userRewardsDetails[_staker];
       return findUser.userReward;
   }

   function totalWalletBalance() public view returns(uint256){
     return IERC20(_rewardToken).balanceOf(address(this));
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
    function rewardOf(address staker) public view returns(uint256) {             
        STAKE memory stakerUser = _stakeInfo[staker];       
        uint256 partitionStakeAmount = SafeMath.div(stakerUser.amount * 100, totalStakeAmount());
        uint256 totalRewardsAmount = SafeMath.sub(totalWalletBalance(),totalUserRewards()); 
        uint256 userIncrementReward = SafeMath.div(SafeMath.mul(totalRewardsAmount, partitionStakeAmount), 100);       
        return userIncrementReward;
    }

    // set reward to
    function setRewardToken(address rewardToken) public onlyOwner {
        require(_rewardToken != address(0), "Avoid Zero Address");
        _rewardToken = rewardToken;
    }

    function setLPToken(address lpToken) public onlyOwner {
        require(_rewardToken != address(0), "Avoid Zero Address");
        _lpToken = lpToken;
    }

    function stake(uint256 _amount) public {
        // send fund to stake holding wallet        
        IERC20(_lpToken).transferFrom(_msgSender(), address(this), _amount);
        STAKE storage _stake = _stakeInfo[_msgSender()];  
        if (_stake.amount > 0) {        
             claimReward();
            _stake.lastUpdatedAt = block.timestamp;
            _stake.amount = SafeMath.add(_stake.amount, _amount);           
            emit Stake(_msgSender(), _amount);
        } else {
            _stake.lastUpdatedAt = block.timestamp;
            _stake.amount = _amount;
            _stakers.push(_msgSender());
            emit Stake(_msgSender(), _amount);
        }       
    }

    function unstake() public {
        require(_stakeInfo[_msgSender()].amount > 0, "Not staking");
        STAKE storage _stake = _stakeInfo[_msgSender()];
        uint256 amount = _stake.amount;
        _stake.amount = 0;
        _stake.lastUpdatedAt = block.timestamp;
        // claim for user reward and re-calculate for rest of them
        claimReward();
        for (uint256 i = 0; i < _stakers.length; i++) {
            if (_stakers[i] == _msgSender()) {
                _stakers[i] = _stakers[_stakers.length - 1];
                _stakers.pop();
                break;
            }
        }

        uint256 fee = SafeMath.div(amount ,100);
        uint256 _amount = SafeMath.sub(amount, fee);
        IERC20(_lpToken).transfer(_msgSender(), _amount);
        IERC20(_lpToken).transfer(NLIFEWallet,fee);
        emit Unstake(_msgSender(), amount);
    }

    function claimReward() public {
        STAKE storage _stake = _stakeInfo[_msgSender()];
        // Calculate for user who claim reward           
        _stake.lastUpdatedAt = block.timestamp;
        uint256 reward = rewardOf(_msgSender());      

        // iterate through rest of the users       
        for(uint i = 0; i < _stakers.length; i++){  
           if(_stakers[i] != _msgSender()){                     
            uint256 newReward = rewardOf(_stakers[i]);
            _userRewardsDetails[_stakers[i]].userReward = SafeMath.add(newReward, _userRewardsDetails[_stakers[i]].userReward);
           }            
        }        
        uint256 totalReward = SafeMath.add(reward, _userRewardsDetails[_msgSender()].userReward);
        _userRewardsDetails[_msgSender()].userReward = 0; 
        IERC20(_rewardToken).transfer(_msgSender(), totalReward);
        emit Withdraw(_msgSender(), totalReward);
    }
  }