// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interface/IDistributor.sol";
import "./interface/IPermit.sol";
import "./library/IterableMapping.sol";

contract ACYStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    using IterableMapping for IterableMapping.Map;
    IterableMapping.Map private userShare;

    uint256 public epochLengthInBlocks;

    address public ACY;
    address public ACYFund;
    uint256 public ACYToDistributeNextEpoch;

    address public sACY;

    uint256 public totalShare;
    uint256 public nextEpochBlock;

    bool public isInitialized;

    event DistributeACYReward(
        uint256 indexed blockNumber,
        address indexed user,
        uint256 reward
    );

    event WithdrawACY(address indexed user, uint256 withdrawAmount);

    event StakeACY(address indexed user, uint256 stakeAmount);

    event StakeACYPermit();

    event WithdrawACYPermit();

    modifier notInitialized() {
        require(!isInitialized);
        _;
    }

    function distributeACYReward() external onlyOwner {
        if (block.number >= nextEpochBlock) {
            nextEpochBlock = nextEpochBlock.add(epochLengthInBlocks);

            uint256 rewards = IDistributor(ACY).getTradeFeeReward();
            IDistributor(ACY).claimTradeFeeReward();

            if (totalShare > 0) {
                uint256 perShare = rewards.div(totalShare);
                uint256 len = userShare.size();

                for (uint256 i = 0; i < len; i++) {
                    address account = userShare.getKeyAtIndex(i);
                    uint256 prevAmount = userShare.get(account);
                    uint256 reward = perShare.mul(prevAmount);
                    IERC20(sACY).safeTransfer(account, reward);
                    userShare.set(account, prevAmount.add(reward));

                    emit DistributeACYReward(block.number, account, reward);
                }
            } else {
                IERC20(sACY).safeTransfer(ACYFund, rewards);
                emit DistributeACYReward(block.number, ACYFund, rewards);
            }
            totalShare = totalShare.add(rewards);
        }
    }

    function getStakingInfo()
        public
        view
        returns (
            uint256 _totalShare,
            uint256 _nextEpochBlock,
            address[] memory users,
            uint256[] memory userShares
        )
    {
        _totalShare = totalShare;
        _nextEpochBlock = nextEpochBlock;

        uint256 len = userShare.size();
        users = new address[](len);
        userShares = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            users[i] = userShare.getKeyAtIndex(i);
            userShares[i] = userShare.get(users[i]);
        }
    }

    function initialze(
        address ACYToken_,
        address sACYToken_,
        address ACYFund_,
        uint256 epochLengthInBlocks_
    ) external notInitialized onlyOwner {
        ACY = ACYToken_;
        sACY = sACYToken_;
        ACYFund = ACYFund_;
        nextEpochBlock = block.number + epochLengthInBlocks_;
        epochLengthInBlocks = epochLengthInBlocks_;
        isInitialized = true;
    }

    function setEpochLengthInBlocks(uint256 newEpochLengthInBlocks_)
        external
        onlyOwner
    {
        epochLengthInBlocks = newEpochLengthInBlocks_;
    }

    function setACYFund(address _acyFund) external onlyOwner {
        ACYFund = _acyFund;
    }

    function getCurrentRewardForNextEpoch()
        public
        view
        returns (uint256 rewards)
    {
        rewards = IDistributor(ACY).getTradeFeeReward();
    }

    function _stakeACY(uint256 stakeAmountACY) internal {
        require(stakeAmountACY >= 0, "stake amount must > 0");

        IERC20(ACY).safeTransferFrom(msg.sender, address(this), stakeAmountACY);
        IERC20(sACY).safeTransfer(msg.sender, stakeAmountACY);
        totalShare = totalShare.add(stakeAmountACY);
        uint256 amount = userShare.get(msg.sender).add(stakeAmountACY);
        userShare.set(msg.sender, amount);

        emit StakeACY(msg.sender, stakeAmountACY);
    }

    function stakeACY(uint256 stakeAmountACY) external returns (bool) {
        _stakeACY(stakeAmountACY);
        return true;
    }

    function stakeACYWithPermit(uint256 stakeAmountACY, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_ ) external returns (bool) {
        IPermit(ACY).permit(
            msg.sender,
            address(this),
            stakeAmountACY,
            deadline_,
            v_,
            r_,
            s_
        );
        _stakeACY(stakeAmountACY);
        return true;
    }



    function _unstakeACY(uint256 withdrawACY) internal {
        require(withdrawACY >= 0, "unstake amount must > 0");
        require(withdrawACY <= totalShare, "amountToWithdraw > totalShare");

        // step1 withdrawACY
        IERC20(sACY).safeTransferFrom(msg.sender, address(this), withdrawACY);
        IERC20(ACY).safeTransfer(msg.sender, withdrawACY);

        // step2 update totalShare
        totalShare = totalShare.sub(withdrawACY);

        // step3 update usesrShare
        uint256 _userShare = userShare.get(msg.sender);
        userShare.set(msg.sender, _userShare.sub(withdrawACY));

        emit WithdrawACY(msg.sender, withdrawACY);
    }

    function unstakeACY(uint256 withdrawACY) external returns (bool) {
        _unstakeACY(withdrawACY);
        return true;
    }
}
