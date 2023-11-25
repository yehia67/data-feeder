// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./interfaces/IBaseOracle.sol";

contract BaseOracle is Ownable, IBaseOracle {
    uint256 internal idCounter = 0;
    uint256 public flatFee = 0;

    mapping(uint256 => bool) public pendingRequests;
    mapping(uint256 => uint256) public apiKeyUsage;
    mapping(address => uint256) public apiKeyByAddress;

    modifier onlyRegistratedUser() {
        require(apiKeyByAddress[msg.sender] > 0, "Unauthorized.");
        _;
    }

    modifier onlyUserWithKey(uint256 apiKey) {
        require(apiKeyByAddress[msg.sender] == apiKey, "Unauthorized.");
        _;
    }

    constructor() Ownable(msg.sender) {}

    function addNewUser(uint256 _apiKey, address _newUser) external onlyOwner {
        apiKeyByAddress[_newUser] = _apiKey;
        emit CreatedApiKey(_apiKey, _newUser);
    }

    function addAddressToApiKey(uint256 _apiKey, address _newUser) external onlyUserWithKey(_apiKey) {
        apiKeyByAddress[_newUser] = _apiKey;
        emit AddedAddressToApiKey(_apiKey, _newUser);
    }

    function setFees(uint256 _flatFees) external onlyOwner {
        flatFee = _flatFees;
        emit UpdateFlatFees(flatFee);
    }
    function withdrawAll() external {
        payable(owner()).transfer(address(this).balance);
    }
}


