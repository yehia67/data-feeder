// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

interface ICaller {
    function fulfillRandomNumberRequest(uint256 randomNumber, uint256 id) external;
}

contract RandOracle is Ownable {
    uint256 private randNonce = 0;

    mapping(uint256 => bool) private pendingRequests;
    mapping(string => uint256) public apiKeyUsage;
    mapping(address => string) public apiKeyByAddress;

    struct Response {
        address providerAddress;
        address callerAddress;
        uint256 randomNumber;
    }

    mapping(uint256 => Response[]) private idToResponses;

    modifier onlyRegistratedUser() {
        require(bytes(apiKeyByAddress[msg.sender]).length > 0, "Unauthorized.");
        _;
    }

    event RandomNumberRequested(uint256 indexed id, address callerAddress);
    event RandomNumberReturned(uint256 indexed id, uint256 randomNumber, address callerAddress);
    event AddApiKey(string indexed _apiKey, address indexed _newUser);

    constructor() Ownable(msg.sender) {}

    function addNewUser(string memory _apiKey, address _newUser) external onlyOwner {
        apiKeyByAddress[_newUser] = _apiKey;
        emit AddApiKey(_apiKey, _newUser);
    }

    function requestRandomNumber() external onlyRegistratedUser returns (uint256) {
        uint256 id = randNonce;
        pendingRequests[id] = true;

        randNonce++;
        apiKeyUsage[apiKeyByAddress[msg.sender]]++;
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
