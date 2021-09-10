// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IDistributor {
    function getTradeFeeReward() external view returns (uint256);

    function claimTradeFeeReward() external;
}