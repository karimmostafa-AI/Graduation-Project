// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GovernmentPropertyVerification is ERC721URIStorage, ReentrancyGuard, Ownable {
    uint256 private _tokenIdCounter;
    uint256 private _itemsSoldCounter;



    address[] private managersList;
    mapping(address => bool) public managers;
    mapping(address => bool) public verificationAgents;

    struct PropertyItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        address buyer;
        uint256 price;
        bool sold;
        bool approved;
        bool rejected;
        string description;
    }

    mapping(uint256 => PropertyItem) private idToPropertyItem;

    event PropertyTransferRejected(uint256 indexed tokenId, string reason);
    event PropertyItemCreated(uint256 indexed tokenId, address seller, address owner, uint256 price, bool sold);
    event PropertyItemSold(uint256 indexed tokenId, address seller, address buyer, uint256 price);
    event ApprovalStatusChanged(uint256 indexed tokenId, bool approved);
    event AgentStatusUpdated(address agent, bool status);
    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);

    modifier onlyPrivileged() {
        require(owner() == msg.sender || managers[msg.sender], "Not authorized");
        _;
    }

    modifier onlyAgent() {
        require(verificationAgents[msg.sender], "Only authorized agents can perform this action");
        _;
    }

    constructor() ERC721("GovernmentPropertyVerification", "GPV") Ownable(msg.sender) {}

    function addManager(address newManager) public onlyPrivileged {
        require(newManager != address(0), "Invalid manager address");
        require(!managers[newManager], "Address is already a manager");
        managers[newManager] = true;
        managersList.push(newManager);
        emit ManagerAdded(newManager);
    }

    function removeManager(address manager) public onlyPrivileged {
        require(managers[manager], "Address is not a manager");
        require(manager != msg.sender, "Cannot remove yourself");
        managers[manager] = false;

        for (uint i = 0; i < managersList.length; i++) {
            if (managersList[i] == manager) {
                managersList[i] = managersList[managersList.length - 1];
                managersList.pop();
                break;
            }
        }

        emit ManagerRemoved(manager);
    }

    function fetchManagers() public view returns (address[] memory) {
        return managersList;
    }


    function setAgent(address agent, bool status) public onlyPrivileged {
        require(agent != address(0), "Invalid agent address");
        verificationAgents[agent] = status;
        emit AgentStatusUpdated(agent, status);
    }


    function getLatestTokenId() public view returns (uint256) {
        return _tokenIdCounter;
    }

    function createPropertyToken(
        string memory _tokenURI,
        uint256 _price,
        address _buyer,
        string memory _description
    ) public payable returns (uint256) {
        require(_price > 0, "Price must be greater than 0");
        require(_buyer != address(0), "Invalid buyer address");
        require(bytes(_description).length > 0, "Description is required");

        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        idToPropertyItem[newTokenId] = PropertyItem(
            newTokenId,
            payable(msg.sender),
            payable(address(this)),
            _buyer,
            _price,
            false,
            false,
            false,
            _description
        );

        _transfer(msg.sender, address(this), newTokenId);

        emit PropertyItemCreated(newTokenId, msg.sender, address(this), _price, false);

        return newTokenId;
    }

    function approvePropertyTransfer(uint256 tokenId) public onlyAgent {
        PropertyItem storage item = idToPropertyItem[tokenId];
        require(!item.sold, "Item already sold");
        require(!item.approved, "Transfer already approved");
        require(!item.rejected, "Transfer already rejected");
        require(item.buyer != address(0), "No buyer specified");

        item.approved = true;
        emit ApprovalStatusChanged(tokenId, true);
    }

    function rejectPropertyTransfer(uint256 tokenId, string memory reason) public onlyAgent {
        PropertyItem storage item = idToPropertyItem[tokenId];
        require(!item.sold, "Item already sold");
        require(!item.approved, "Transfer already approved");
        require(!item.rejected, "Transfer already rejected");

        item.rejected = true;
        emit PropertyTransferRejected(tokenId, reason);
    }

    function purchaseProperty(uint256 tokenId) public payable nonReentrant {
        PropertyItem storage item = idToPropertyItem[tokenId];
        require(!item.sold, "Item already sold");
        require(!item.rejected, "Transfer rejected");
        require(item.approved, "Transfer not approved");
        require(item.buyer == msg.sender, "Not designated buyer");
        require(msg.value == item.price , "Incorrect payment amount");

        address payable seller = item.seller;

        item.owner = payable(msg.sender);
        item.sold = true;
        _itemsSoldCounter++;
        _transfer(address(this), msg.sender, tokenId);

        seller.transfer(msg.value);

        emit PropertyItemSold(tokenId, seller, msg.sender, item.price);
    }

    // Fetch all stored properties
    function fetchProperties() public view returns (PropertyItem[] memory) {
        uint256 totalProperties = _tokenIdCounter;
        PropertyItem[] memory items = new PropertyItem[](totalProperties);

        for (uint256 i = 0; i < totalProperties; i++) {
            PropertyItem storage currentItem = idToPropertyItem[i + 1];
            items[i] = currentItem;
        }

        return items;
    }

    // Fetch properties by owner
    function fetchMyProperties() public view returns (PropertyItem[] memory) {
        uint256 totalProperties = _tokenIdCounter;
        uint256 myPropertiesCount = 0;
        
        // First, count the number of properties owned by the caller
        for (uint256 i = 1; i <= totalProperties; i++) {
            if (idToPropertyItem[i].owner == msg.sender) {
                myPropertiesCount++;
            }
        }
        
        // Create an array of the correct size
        PropertyItem[] memory myProperties = new PropertyItem[](myPropertiesCount);
        uint256 currentIndex = 0;
        
        // Fill the array with the caller's properties
        for (uint256 i = 1; i <= totalProperties; i++) {
            if (idToPropertyItem[i].owner == msg.sender) {
                myProperties[currentIndex] = idToPropertyItem[i];
                currentIndex++;
            }
        }
        
        return myProperties;
    }

    // Fetch properties listed by seller
    function fetchMyListedProperties() public view returns (PropertyItem[] memory) {
        uint256 totalProperties = _tokenIdCounter;
        uint256 listedCount = 0;
        
        // First, count the number of properties listed by the caller
        for (uint256 i = 1; i <= totalProperties; i++) {
            if (idToPropertyItem[i].seller == msg.sender && !idToPropertyItem[i].sold) {
                listedCount++;
            }
        }
        
        // Create an array of the correct size
        PropertyItem[] memory listedProperties = new PropertyItem[](listedCount);
        uint256 currentIndex = 0;
        
        // Fill the array with the caller's listed properties
        for (uint256 i = 1; i <= totalProperties; i++) {
            if (idToPropertyItem[i].seller == msg.sender && !idToPropertyItem[i].sold) {
                listedProperties[currentIndex] = idToPropertyItem[i];
                currentIndex++;
            }
        }
        
        return listedProperties;
    }
}
