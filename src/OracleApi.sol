// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract OracleApi is Ownable {
    uint256 private idCounter = 0;

    mapping(uint256 => bool) public pendingRequests;
    mapping(uint256 => uint256) public apiKeyUsage;
    mapping(address => uint256) public apiKeyByAddress;

    uint256 public flatFee = 0;

    struct Response {
        address providerAddress;
        string url;
        string value;
    }

    mapping(uint256 => Response[]) private idToResponses;

    modifier onlyRegistratedUser() {
        require(apiKeyByAddress[msg.sender] > 0, "Unauthorized.");
        _;
    }

    modifier onlyUserWithKey(uint256 apiKey) {
        require(apiKeyByAddress[msg.sender] == apiKey, "Unauthorized.");
        _;
    }

    event OracleRequested(uint256 indexed id, address indexed caller, string url);
    event OracleReturned(uint256 indexed id, string value);

    event UpdateFlatFees(uint256 indexed _flatFees);

    event CreatedApiKey(uint256 indexed _apiKey, address indexed _newUser);
    event AddedAddressToApiKey(uint256 indexed _apiKey, address indexed _newUser);

    constructor() Ownable(msg.sender) {}

    function addNewUser(uint256 _apiKey, address _newUser) external onlyOwner {
        apiKeyByAddress[_newUser] = _apiKey;
        emit CreatedApiKey(_apiKey, _newUser);
    }

    function addAddressToApiKey(uint256 _apiKey, address _newUser) external onlyUserWithKey(_apiKey) {
        apiKeyByAddress[_newUser] = _apiKey;
        emit AddedAddressToApiKey(_apiKey, _newUser);
    }

    function requestOracle(string memory url) external payable onlyRegistratedUser returns (uint256) {
        require(msg.value >= flatFee, "Insufficient fee sent");
        uint256 id = idCounter;
        pendingRequests[id] = true;

        idCounter++;
        apiKeyUsage[apiKeyByAddress[msg.sender]]++;
        emit OracleRequested(id, msg.sender, url);
        return id;
    }

    function setFees(uint256 _flatFees) external onlyOwner {
        flatFee = _flatFees;
        emit UpdateFlatFees(flatFee);
    }

    function setOracleResult(uint256 id, string memory url, string memory response) external onlyOwner {
        require(pendingRequests[id], "Request not found.");

        // Add newest response to list
        Response memory res = Response(msg.sender, url, response);
        idToResponses[id].push(res);

        // Clean up
        delete pendingRequests[id];
        delete idToResponses[id];

        emit OracleReturned(id, response);
    }

    function withdrawAll() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
// cast send 0x7d2fde48f4a7A8e309B9ed62a9a6a223b4dEbC34 "function addNewUser(string memory _apiKey, address _newUser)" 01dd37d1-ae8c-48f0-ac5f-682877fd175f 0x0f5BD75fbB7593Efa4dCC013Ae19b9F498459223    --rpc-url https://rpc.topos-subnet.testnet-1.topos.technology --private-key 6d97bda69af03bae83764c240a89ff090538eb34500e2c2e23addfd8b5e4fdcc --legacy
// cast send 0x7d2fde48f4a7A8e309B9ed62a9a6a223b4dEbC34 "function  setFees(uint256 _flatFees)" 0    --rpc-url https://rpc.topos-subnet.testnet-1.topos.technology --private-key 6d97bda69af03bae83764c240a89ff090538eb34500e2c2e23addfd8b5e4fdcc --legacy
