// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Learn more about the ERC20 implementation 
// on OpenZeppelin docs: https://docs.openzeppelin.com/contracts/4.x/erc20
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract PolarityTestToken is Context, ERC20 {
    constructor() ERC20("Polarity TestETH Token Rewards", "PETR") {
        _mint(msg.sender, 10000 * 10 ** 18);
    }
}