// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "./BaseOracle.sol";

contract OracleApi is BaseOracle {
    struct Response {
        address providerAddress;
        string url;
        string value;
    }

    mapping(uint256 => Response[]) private idToResponses;

    event OracleRequested(uint256 indexed id, address indexed caller, string url);
    event OracleReturned(uint256 indexed id, string value);

    function requestOracle(string memory url) external payable onlyRegistratedUser returns (uint256) {
        require(msg.value >= flatFee, "Insufficient fee sent");
        uint256 id = idCounter;
        pendingRequests[id] = true;

        idCounter++;
        apiKeyUsage[apiKeyByAddress[msg.sender]]++;
        emit OracleRequested(id, msg.sender, url);
        return id;
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
}
