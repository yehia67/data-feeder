// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

interface ICaller {
    function fulfillRandomNumberRequest(uint256 randomNumber, uint256 id) external;
}

contract RandOracle is Ownable {
    uint256 private randNonce = 0;

    mapping(uint256 => bool) private pendingRequests;
    mapping(bytes32 => uint256) public apiKeyUsage;

    struct Response {
        address providerAddress;
        address callerAddress;
        uint256 randomNumber;
    }

    mapping(uint256 => Response[]) private idToResponses;

    event RandomNumberRequested(uint256 indexed id, address callerAddress);
    event RandomNumberReturned(uint256 indexed id, uint256 randomNumber, address callerAddress);

    constructor() Ownable(msg.sender) {}

    function requestRandomNumber() external returns (uint256) {
        randNonce++;
        uint256 id = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 1000;
        pendingRequests[id] = true;

        emit RandomNumberRequested(id, msg.sender);
        return id;
    }

    function returnRandomNumber(uint256 randomNumber, address callerAddress, uint256 id) external onlyOwner {
        require(pendingRequests[id], "Request not found.");

        // Add newest response to list
        Response memory res = Response(msg.sender, callerAddress, randomNumber);
        idToResponses[id].push(res);

        // Clean up
        delete pendingRequests[id];
        delete idToResponses[id];

        // Fulfill request
        ICaller(callerAddress).fulfillRandomNumberRequest(id, randomNumber);

        emit RandomNumberReturned(id, randomNumber, callerAddress);
    }
}
