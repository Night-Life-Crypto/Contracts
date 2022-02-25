pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract UserRewards is Context, Ownable{

    address public lpToken;
    address public rewardToken;
    
	address public NLIFEWallet;

    struct USERREWARD{
        uint256 reward;
        uint256 lastUpdateAt;
    }

    struct STAKE {
        uint256 amount;
        uint256 lastUpdatedAt;
    }

    mapping(address => STAKE) public _stakeInfo;
    mapping(address => USERREWARD) public _userRewardsDetails;
    address[] public _stakers;
    address[] public _userRewards;

    constructor(address _rewardToken) public {
        rewardToken = _rewardToken;
        NLIFEWallet = _msgSender();
    }

    event UserReward(address _staker, uint256 amount);
    event Stake(address _staker, uint256 amount);

    function userReward(address _staker, uint256 _amount) public {
        emit UserReward(_staker, _amount);
    }

    function setRewardToken(address _rewardToken) public onlyOwner {
      rewardToken = _rewardToken;
    }

    function setStaker(address account) public{
        _stakers.push(account);
    }

    function getStaker(address account) public view returns (uint256){
        STAKE memory _stakeDetials = _stakeInfo[account];
        return _stakeDetials.amount;
    }

   function setUserReward(uint256 balance, address user) public {
       USERREWARD memory userRew = USERREWARD({reward: balance, lastUpdateAt: block.timestamp });
       _userRewards[user] = userRew;
   }

   function getUserReward(address user) public view returns (uint256) {
       USERREWARD memory findUser = _userRewardsDetails[user];
       return findUser.reward;
   }

   function getNlifeDAppBalance() public view returns (uint256) {
       return NLIFEWallet.balance;
   }
  
    function totalRewards() public view returns (uint256) {
        return address(this).balance;
    }

    function totalUsersRewards() public view returns (uint256){
        uint totalRewards = 0;
        for(uint i=0 ;i< 2; i++){
          // totalRewards = totalRewards + _sta
        }
    }

}