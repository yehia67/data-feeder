// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "./BaseOracle.sol";

contract OraclePrice is BaseOracle {
    struct Response {
        address providerAddress;
        string fiatName;
        uint256 cryptoValue;
    }

    mapping(uint256 => Response[]) private idToResponses;

    event OracleRequested(uint256 indexed id, address indexed caller, string fiatSymbol, string ccSymbol);
    event OracleReturned(uint256 indexed id, string fiatName, uint256 cryptoValue);

    function requestOracle(string memory fiatSymbol, string memory ccSymbol)
        external
        payable
        onlyRegistratedUser
        returns (uint256)
    {
        require(msg.value >= flatFee, "Insufficient fee sent");
        uint256 id = idCounter;
        pendingRequests[id] = true;

        idCounter++;
        apiKeyUsage[apiKeyByAddress[msg.sender]]++;
        emit OracleRequested(id, msg.sender, fiatSymbol, ccSymbol);
        return id;
    }

    function setOracleResult(uint256 id, string memory fiatSymbol, uint256 ccValue) external onlyOwner {
        require(pendingRequests[id], "Request not found.");

        // Add newest response to list
        Response memory res = Response(msg.sender, fiatSymbol, ccValue);
        idToResponses[id].push(res);

        // Clean up
        delete pendingRequests[id];
        delete idToResponses[id];

        emit OracleReturned(id, fiatSymbol, ccValue);
    }
}
