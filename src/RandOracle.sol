// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

interface ICaller {
    function fulfillRandomNumberRequest(uint256 randomNumber, uint256 id) external;
}

contract RandOracle is Ownable {
    uint256 private randNonce = 0;

    mapping(uint256 => bool) public pendingRequests;
    mapping(string => uint256) public apiKeyUsage;
    mapping(address => string) public apiKeyByAddress;

    uint256 public flatFee;

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
    event UpdateFlatFees(uint256 indexed _flatFees);

    constructor() Ownable(msg.sender) {}

    function addNewUser(string memory _apiKey, address _newUser) external onlyOwner {
        apiKeyByAddress[_newUser] = _apiKey;
        emit AddApiKey(_apiKey, _newUser);
    }

    function requestRandomNumber() external payable onlyRegistratedUser returns (uint256) {
        require(msg.value >= flatFee, "Insufficient fee sent");
        uint256 id = randNonce;
        pendingRequests[id] = true;

        randNonce++;
        apiKeyUsage[apiKeyByAddress[msg.sender]]++;
        emit RandomNumberRequested(id, msg.sender);
        return id;
    }

    function setFees(uint256 _flatFees) external onlyOwner {
        flatFee = _flatFees;
        emit UpdateFlatFees(flatFee);
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
// cast send 0x7d2fde48f4a7A8e309B9ed62a9a6a223b4dEbC34 "function addNewUser(string memory _apiKey, address _newUser)" 01dd37d1-ae8c-48f0-ac5f-682877fd175f 0x0f5BD75fbB7593Efa4dCC013Ae19b9F498459223    --rpc-url https://rpc.topos-subnet.testnet-1.topos.technology --private-key 6d97bda69af03bae83764c240a89ff090538eb34500e2c2e23addfd8b5e4fdcc --legacy
// cast send 0x7d2fde48f4a7A8e309B9ed62a9a6a223b4dEbC34 "function  setFees(uint256 _flatFees)" 0    --rpc-url https://rpc.topos-subnet.testnet-1.topos.technology --private-key 6d97bda69af03bae83764c240a89ff090538eb34500e2c2e23addfd8b5e4fdcc --legacy
