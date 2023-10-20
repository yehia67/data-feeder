// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract RandOracle is AccessControl {
    bytes32 public constant PROVIDER_ROLE = keccak256("PROVIDER_ROLE");
    uint256 private numProviders = 0;
    uint256 private providersThreshold = 1;

    uint256 private randNonce = 0;

    mapping(uint256 => bool) private pendingRequests;

    struct Response {
        address providerAddress;
        address callerAddress;
        uint256 randomNumber;
    }

    mapping(uint256 => Response[]) private idToResponses;

    constructor() {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // make the deployer admin
    }

    function requestRandomNumber() external returns (uint256) {
        require(numProviders > 0, " No data providers not yet added.");

        randNonce++;
        uint256 id = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 1000;
        pendingRequests[id] = true;

        emit RandomNumberRequested(msg.sender, id);
        return id;
    }

    function returnRandomNumber(uint256 randomNumber, address callerAddress, uint256 id)
        external
        onlyRole(PROVIDER_ROLE)
    {
        require(pendingRequests[id], "Request not found.");

        // Add newest response to list
        Response memory res = Response(msg.sender, callerAddress, randomNumber);
        idToResponses[id].push(res);
        uint256 numResponses = idToResponses[id].length;

        // Check if we've received enough responses
        if (numResponses == providersThreshold) {
            uint256 compositeRandomNumber = 0;

            // Loop through the array and combine responses
            for (uint256 i = 0; i < idToResponses[id].length; i++) {
                compositeRandomNumber = compositeRandomNumber ^ idToResponses[id][i].randomNumber; // bitwise XOR
            }

            // Clean up
            delete pendingRequests[id];
            delete idToResponses[id];

            // Fulfill request
            // ICaller(callerAddress).fulfillRandomNumberRequest(compositeRandomNumber, id);

            emit RandomNumberReturned(compositeRandomNumber, callerAddress, id);
        }
    }

    // Admin functions
    function addProvider(address provider) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!hasRole(PROVIDER_ROLE, provider), "Provider already added.");

        _grantRole(PROVIDER_ROLE, provider);
        numProviders++;

        emit ProviderAdded(provider);
    }

    function removeProvider(address provider) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!hasRole(PROVIDER_ROLE, provider), "Address is not a recognized provider.");
        require(numProviders > 1, "Cannot remove the only provider.");

        _revokeRole(PROVIDER_ROLE, provider);
        numProviders--;

        emit ProviderRemoved(provider);
    }

    function setProvidersThreshold(uint256 threshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(threshold > 0, "Threshold cannot be zero.");

        providersThreshold = threshold;
        emit ProvidersThresholdChanged(providersThreshold);
    }

    // Events
    event RandomNumberRequested(address callerAddress, uint256 id);
    event RandomNumberReturned(uint256 randomNumber, address callerAddress, uint256 id);
    event ProviderAdded(address providerAddress);
    event ProviderRemoved(address providerAddress);
    event ProvidersThresholdChanged(uint256 threshold);
}
