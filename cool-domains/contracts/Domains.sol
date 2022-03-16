// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

// import OpenZeppelin Contracts.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import { StringUtils } from "./libraries/StringUtils.sol";
import { Base64 } from "./libraries/Base64.sol";

import "hardhat/console.sol";


// We inherit the contract we imported so we have access to the inherited contract's methods.
contract Domains is ERC721URIStorage {
    // Magic from OpenZeppelin to help track tokeIds.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Top level domain (TLD)
    string public tld;

    // Stroing our NFT images on chain as SVGs
    string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><rect x="20" y="20" width="30" height="30" stroke="white" fill="transparent" stroke-width="5"/><rect x="30" y="30" width="30" height="30" stroke="gray" fill="transparent" stroke-width="5"/><rect x="40" y="40" width="30" height="30" stroke="#483C32" fill="transparent" stroke-width="5"/><defs><linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#EADDCA"/><stop offset="1" stop-color="#6F4E37" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = '</text></svg>';

    // mapping to store domain names
    mapping(string => address) public domains;
    mapping(string => string) public records;
    mapping(string => string) public twitters;
    mapping(uint => string) public names;

    address payable public owner;

    error Unauthorized();
    error AlreadyRegistered();
    error InvalidName(string name);


    // We make the contract "payable" by adding this to the constructor
    constructor(string memory _tld) payable ERC721("Bear Name Service", "BNS") {
        owner = payable(msg.sender);
        tld = _tld;
        console.log("%s name service deployed", _tld);
    }

    // This function gives us the price of a domain based on length
    function price(string calldata name) public pure returns(uint) {
        uint len = StringUtils.strlen(name);
        require(len > 0);
        if (len == 3) {
            return 5 * 10**17; // 5 MATIC  = 5 000 000 000 000 000 000 (18 decimals). Going with 0.5 MATIC due to faucets
        } else if (len == 4) {
            return 3 * 10**17; // 0.3 MATIC
        } else {
            return 1 * 10**17; // 0.1 MATIC
        }
    }
    
    // A register function that adds names to our mapping
    function register(string calldata name) public payable {
        // Check that the name is unregistered
        if (domains[name] != address(0)) revert AlreadyRegistered();
        if (!valid(name)) revert InvalidName(name);

        uint256 _price = price(name);

        // Check if enough Matic was paid in the transaction.
        require(msg.value >= _price, "Not enough MATIC paid");

        // Combine the name passed into the function with the TLD
        string memory _name = string(abi.encodePacked(name, ".", tld));
        //Create the SVG for the NFT with the name
        string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        console.log("Registering %s.%s on the contract with tokenID %d", name, tld, newRecordId);

        // Create the JSON metadata of our NFT. We do this by comgining strings and encoding as base64
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        _name,
                        '", "description": "A domain on the Bear Name Service", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '","length":"',
                        strLen,
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(abi.encodePacked("data:application/json;base64,", json));

        console.log("\n-----------------------------------------------------");
        console.log("Final tokenURI", finalTokenUri);
        console.log("-----------------------------------------------------\n");

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);

        domains[name] = msg.sender;

        names[newRecordId] = name;
        
        _tokenIds.increment();
    }

    // This will give us the domain owners' addresses
    function getAddress(string calldata name) public view returns (address) {
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public {
        // Check that the owner is the transaction sender
        if (msg.sender != domains[name]) revert Unauthorized();
        records[name] = record;
    }

    function getRecord(string calldata name) public view returns(string memory) {
        return records[name];
    }

    function setTwitter(string calldata name, string calldata twitter) public {
        require(domains[name] == msg.sender);
        twitters[name] = twitter;
    }

    function getTwitter(string calldata name) public view returns(string memory) {
        return twitters[name];
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw Matic");
    }

    function getAllNames() public view returns (string[] memory) {
        console.log("Getting all names from contract");
        string[] memory allNames = new string[](_tokenIds.current());
        for (uint i = 0; i < _tokenIds.current(); i++) {
            allNames[i] = names[i];
            console.log("Name for token %d is %s", i, allNames[i]);
        }

        return allNames;
    }

    function valid(string calldata name) public pure returns(bool) {
        return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 9;
    }
}