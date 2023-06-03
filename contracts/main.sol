// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract Blockcharity {
    //Tracking of donations - Done
    mapping(address => uint256) public amountDonated;
    mapping(address => bool) public hasDonated;
    address public owner;
    address[] public donors;
    struct Donation {
        address donor;
        uint256 value;
    }

    Donation[] public donations;

    receive() external payable {
        donations.push(Donation(msg.sender, msg.value));
        amountDonated[msg.sender] += msg.value;
        if (hasDonated[msg.sender] == false) {
            hasDonated[msg.sender] = true;
            donors.push(msg.sender);
        }
    }

    //Staff  - Done

    mapping(address => bool) staff;

    constructor() {
        owner = msg.sender;
        staff[msg.sender] = true;
        inUseAmt = 0;
    }

    modifier isStaff() {
        require(staff[msg.sender] == true, "This function is locked.");
        _;
    }

    function addStaff(address newStaff) external {
        require(msg.sender == owner, "This function is locked.");
        staff[newStaff] = true;
    }

    //Organizations - Need Review

    struct Organization {
        address owner;
        uint256 totalReceived;
        string name;
        uint256 class;
    }

    /*
    Class 1 = Verified = 1
    Class 2 = Unverified = 2
    Class 3 = Defunct or Scam = 3
    */
    Organization[] public Organizations;
    uint256 public numberOfOrgs = 0;


    function getOrganizations() public view returns (Organization[] memory) {
        return Organizations;
    }

    function registerOrganization(address, string memory name) public payable {
        Organizations.push(Organization(msg.sender, 0, name, 2));
        numberOfOrgs++;
    }

    function changeClass(uint256 id, uint256 newClass) external isStaff {
        require(Organizations[id].owner != address(0x0), "Organization Does Not Exist");
        require(1 <= newClass && newClass <= 3, "Invalid Class ID"); //Does class exist?
        require(Organizations[id].class != newClass, "Organization is already in that class"); //Useless Tx
        Organizations[id].class = newClass;

    }

    //Donate - Done

    function donate(uint256 id) public payable {
        require(msg.value > 0, "Cannot donate nothing");
        require(Organizations[id].class != 3, "Organization is a scam");
        payable(Organizations[id].owner).transfer(msg.value);
    }

    //Grants

    uint256 public inUseAmt;

    struct Grant {
        uint256 organizationId;
        uint256 amount;
        string description;
        uint256 endDate;
    }

    Grant[] public grants;

    function requestGrant(uint256 id, uint256 amount_, string memory description_) public {
        require(Organizations[id].owner == msg.sender); //Sender is owner
        require(Organizations[id].class == 1); //Verified
        require((address(this).balance - inUseAmt) / 10 >= amount_); //Cannot request too much
        inUseAmt += amount_;
        grants.push(Grant(id, amount_, description_, block.timestamp + 1 weeks));
    }

    //Create Vote Lock - Unfinished

    struct Lock {
        uint256 end;
        uint256 value;
    }

    mapping(address => Lock) Locks;

    function createLock(uint256 end_) public payable {
        require(msg.value > 0);
        require(Locks[msg.sender].value == 0);
        require(block.timestamp < end_);
        Locks[msg.sender].end = end_;
        Locks[msg.sender].value = msg.value;
    }
    function claimLock() public {
        require(Locks[msg.sender].end <= block.timestamp);
        require(Locks[msg.sender].value != 0);
        uint256 amtToSend = Locks[msg.sender].value;
        Locks[msg.sender].value = 0;
        Locks[msg.sender].end = 0;
        payable(msg.sender).transfer(amtToSend);
    }

    function addToLock() public payable {
        require(msg.value > 0);
        require(Locks[msg.sender].end != 0);
        require(Locks[msg.sender].value != 0);
        require(block.timestamp < Locks[msg.sender].end);
        Locks[msg.sender].value += msg.value;
    }
}
