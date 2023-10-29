// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

interface IBaseOracle {
    event UpdateFlatFees(uint256 indexed _flatFees);

    event CreatedApiKey(uint256 indexed _apiKey, address indexed _newUser);
    event AddedAddressToApiKey(uint256 indexed _apiKey, address indexed _newUser);

    function addNewUser(uint256 _apiKey, address _newUser) external;
    function addAddressToApiKey(uint256 _apiKey, address _newUser) external;
    function setFees(uint256 _flatFees) external;
    function withdrawAll() external;
}
