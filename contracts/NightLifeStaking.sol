pragma solidity ^0.6.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract NightLifeStaking is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    address lpToken;
    address rewardToken;
    
	address NLIFEWallet;

    struct STAKE {
        uint256 amount;
        uint256 _lastUpdatedAt;
    }

    mapping(address => STAKE) _stakeInfo;
    address[] _stakers;

    event Stake(address _staker, uint256 amount);
    event Unstake(address _staker, uint256 amount);
    event Withdraw(address _staker, uint256 amount);

    constructor(address _rewardToken) public {
        rewardToken = _rewardToken;
        NLIFEWallet = _msgSender();
    }

    /**
     * @dev update NLIFE wallet address
     */

    function updateNLIFEWallet(address _newAddr) public onlyOwner {
        NLIFEWallet = _newAddr;
    }

    function totalRewards() public view returns (uint256) {
        return IERC20(rewardToken).balanceOf(address(this));
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

    function rewardOf(address _staker) public view returns (uint256) {
        STAKE memory _stakeDetail = _stakeInfo[_staker];

        uint256 _rewards = totalRewards();
        uint256 _singlePart =
            _stakeDetail.amount.mul(
                block.timestamp.sub(_stakeDetail._lastUpdatedAt)
            );

        uint256 _totalPart;

        for (uint256 i = 0; i < _stakers.length; i++) {
            STAKE memory _singleStake = _stakeInfo[_stakers[i]];

            _totalPart = _totalPart.add(
                _singleStake.amount.mul(
                    block.timestamp.sub(_singleStake._lastUpdatedAt)
                )
            );
        }

        if (_totalPart == 0) return 0;

        return _rewards.mul(_singlePart).div(_totalPart);
    }

    function stake(uint256 _amount) public {
        IERC20(lpToken).safeTransferFrom(_msgSender(), address(this), _amount);

        STAKE storage _stake = _stakeInfo[_msgSender()];

        if (_stake.amount > 0) {
            uint256 reward = rewardOf(_msgSender());
            IERC20(rewardToken).safeTransfer(_msgSender(), reward);
            _stake.amount = _stake.amount.add(_amount);
            emit Withdraw(_msgSender(), reward);
        } else {
            _stake.amount = _amount;
            _stakers.push(_msgSender());
        }

        _stake._lastUpdatedAt = block.timestamp;

        emit Stake(_msgSender(), _amount);
    }

    function unstake() public {
        require(_stakeInfo[_msgSender()].amount > 0, "Not staking");

        STAKE storage _stake = _stakeInfo[_msgSender()];
        uint256 reward = rewardOf(_msgSender());
        uint256 amount = _stake.amount;

        IERC20(rewardToken).safeTransfer(_msgSender(), reward);

        _stake.amount = 0;
        _stake._lastUpdatedAt = block.timestamp;

        for (uint256 i = 0; i < _stakers.length; i++) {
            if (_stakers[i] == _msgSender()) {
                _stakers[i] = _stakers[_stakers.length - 1];
                _stakers.pop();
                break;
            }
        }

        uint256 fee = amount.div(100);
        uint256 _amount = amount.sub(fee);
        IERC20(lpToken).safeTransfer(_msgSender(), _amount);
        IERC20(lpToken).safeTransfer(NLIFEWallet, fee);
        emit Unstake(_msgSender(), amount);
    }

    function claimReward() public {
        STAKE storage _stake = _stakeInfo[_msgSender()];
        uint256 reward = rewardOf(_msgSender());
        _stake._lastUpdatedAt = block.timestamp;

        IERC20(rewardToken).safeTransfer(_msgSender(), reward);
        emit Withdraw(_msgSender(), reward);
    }
}