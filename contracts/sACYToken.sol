// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract sACYToken is ERC20, Ownable {
    using SafeMath for uint256;

    address public stakingContract;
    uint256 constant _totalSupply = 2 * 1e8 * 1e18;

    constructor(address _stakingContract) ERC20("Staked ACY", "sACY") {
        stakingContract = _stakingContract;
        _mint(stakingContract, _totalSupply);
    }
}
