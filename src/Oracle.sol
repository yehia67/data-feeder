// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Oracle is Ownable {
    constructor() Ownable(msg.sender) {}

    function updateOracle() external onlyOwner {}
}
