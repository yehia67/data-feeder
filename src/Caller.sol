// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IRandOracle {
    function requestRandomNumber() external returns (uint256);
}

contract Caller is Ownable {
    IRandOracle private randOracle;

    mapping(uint256 => bool) requests;
    mapping(uint256 => uint256) results;

    modifier onlyRandOracle() {
        require(msg.sender == address(randOracle), "Unauthorized.");
        _;
    }

    constructor() Ownable(msg.sender) {}

    function setRandOracleAddress(address newAddress) external onlyOwner {
        randOracle = IRandOracle(newAddress);

        emit OracleAddressChanged(newAddress);
    }

    function getRandomNumber() external {
        require(randOracle != IRandOracle(address(0)), "Oracle not initialized.");

        uint256 id = randOracle.requestRandomNumber();
        requests[id] = true;

        emit RandomNumberRequested(id);
    }

    function fulfillRandomNumberRequest(uint256 randomNumber, uint256 id) external onlyRandOracle {
        require(requests[id], "Request is invalid or already fulfilled.");

        results[id] = randomNumber;
        delete requests[id];

        emit RandomNumberReceived(id, randomNumber);
    }

    event OracleAddressChanged(address indexed oracleAddress);
    event RandomNumberRequested(uint256 indexed id);
    event RandomNumberReceived(uint256 indexed id, uint256 number);
}

