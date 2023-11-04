// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "./BaseOracle.sol";

contract OraclePokemon is BaseOracle, ERC721 {
    using Strings for uint256;

    uint256 public tokenCounter = 0;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    struct Response {
        address creator;
        string uri;
    }

    mapping(uint256 => Response[]) private idToResponses;

    event OracleRequested(uint256 indexed id, address indexed caller);
    event OracleReturned(uint256 indexed id, string indexed tokenUri);

    constructor() ERC721("Pokemon", "Pokemon") {}

    function requestOracle() external payable onlyRegistratedUser returns (uint256) {
        require(msg.value >= flatFee, "Insufficient fee sent");
        uint256 id = idCounter;
        pendingRequests[id] = true;

        idCounter++;
        apiKeyUsage[apiKeyByAddress[msg.sender]]++;
        emit OracleRequested(id, msg.sender);
        return id;
    }

    function setOracleResult(uint256 id, address to, string memory tokenUri) external onlyOwner {
        require(pendingRequests[id], "Request not found.");

        // Add newest response to list
        Response memory res = Response(msg.sender, tokenUri);
        idToResponses[id].push(res);

        // Clean up
        delete pendingRequests[id];

        mintNFT(to, tokenUri);

        emit OracleReturned(id, tokenUri);
    }

    function mintNFT(address to, string memory tokenURI) internal returns (uint256) {
        uint256 tokenId = tokenCounter;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        tokenCounter++;
        return tokenId;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(tokenId <= tokenCounter, "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
}