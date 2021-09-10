// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ACYToken is ERC20, Ownable {
    using SafeMath for uint256;

    address stakingContract;

    uint256 public constant TRADE_FEE_REWARD = 1000 * 1e18;

    struct TradeFeeRewardData {
        uint256 amount;
        uint256 lastTime;
    }

    event ClaimTradeFeeReward(address user, uint256 reward);

    mapping(address => TradeFeeRewardData) UserRewardData;

    constructor(address _stakingContract) ERC20("ACY Token", "ACY") {
        stakingContract = _stakingContract;
    }

    function distributeTradeFeeReward() external onlyOwner {
        TradeFeeRewardData storage stakingReward = UserRewardData[
            stakingContract
        ];
        stakingReward.amount = stakingReward.amount.add(TRADE_FEE_REWARD);
        stakingReward.lastTime = block.timestamp;
        _mint(address(this), TRADE_FEE_REWARD);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function setStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = _stakingContract;
    }

    function getTradeFeeReward() public view returns (uint256 amount) {
        TradeFeeRewardData storage stakingReward = UserRewardData[msg.sender];

        amount = stakingReward.amount;
        // lastTime = stakingReward.lastTime;
    }

    function claimTradeFeeReward() external {
        require(
            msg.sender == stakingContract,
            "only stakingContract could call"
        );
        TradeFeeRewardData storage stakingReward = UserRewardData[msg.sender];

        _transfer(address(this), msg.sender, stakingReward.amount);

        emit ClaimTradeFeeReward(msg.sender, stakingReward.amount);


        stakingReward.amount = 0;
        stakingReward.lastTime = block.timestamp;

    }
}
