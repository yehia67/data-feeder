// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IRandOracle {
    function requestRandomNumber() external returns (uint256);
}

contract Caller is Ownable {
    IRandOracle private randOracle;

    mapping(uint256 => bool) public requests;
    mapping(uint256 => uint256) public results;

    modifier onlyRandOracle() {
        require(msg.sender == address(randOracle), "Unauthorized.");
        _;
    }

    event OracleAddressChanged(address indexed oracleAddress);
    event RandomNumberRequested(uint256 indexed id);
    event RandomNumberReceived(uint256 indexed id, uint256 number);

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
}

// cast send 0x0f5BD75fbB7593Efa4dCC013Ae19b9F498459223 "function setRandOracleAddress(address newAddress)"  0xAc91bDd0EcbeC973a802eD9fc163706D59EB4BA5  --rpc-url https://rpc.topos-subnet.testnet-1.topos.technology --private-key 6d97bda69af03bae83764c240a89ff090538eb34500e2c2e23addfd8b5e4fdcc
// cast send 0x0f5BD75fbB7593Efa4dCC013Ae19b9F498459223 "function getRandomNumber()"    --rpc-url https://rpc.topos-subnet.testnet-1.topos.technology --private-key 6d97bda69af03bae83764c240a89ff090538eb34500e2c2e23addfd8b5e4fdcc --legacy
