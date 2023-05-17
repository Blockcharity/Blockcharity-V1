// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract Blockcharity {
    //Tracking of donations - Done
    mapping(address => uint256) public amountDonated;
    mapping(address => bool) public hasDonated;
    address public owner;
    address[] public donors;
    uint256 public grantsFund = 0;
    uint256 public weeklyFund = 0;
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
        weeklyFund += (msg.value / 2);
        grantsFund += (msg.value / 2);
    }

    //Staff  - Done

    mapping(address => bool) staff;

    constructor() {
        owner = msg.sender;
        staff[msg.sender] = true;
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
        address SendTo;
        uint256 totalReceived;
        uint256 id;
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
        Organizations.push(Organization(msg.sender, 0, numberOfOrgs, name, 2));
        numberOfOrgs++;
    }

    function changeClass(uint256 id, uint256 newClass) external isStaff {
        require(Organizations[id].SendTo != address(0x0), "Organization Does Not Exist");
        require(1 <= newClass && newClass <= 3, "Invalid Class ID"); //Does class exist?
        require(Organizations[id].class != newClass, "Organization is already in that class"); //Useless Tx
        Organizations[id].class = newClass;

    }

    //Weekly Vote - Need Review

    function getVoters(uint256 week) public view returns (address[] memory) {
        return (voters[week]); //this value cannot be retrieved unless individually
    }

    struct Proposal {
        uint256 outcome;
    }
    struct Vote {
        bool hasVoted;
        uint256 orgTo;
        uint256 amount;
    }

    mapping(uint256 => mapping(uint256 => uint256)) public orgVotes;
    mapping(uint256 => mapping(address => Vote)) public votes;
    mapping(uint256 => address[]) public voters;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => uint256) public winningOrganizations;

    function vote(uint256 id) external payable {
    uint256 week = block.timestamp / 604800;
    require(msg.value > 0, "Insufficient value");
    require(Organizations[id].class == 1, "This organization does not exist, or is not verified.");
    require(votes[week][msg.sender].hasVoted == false, "You have already voted.");
    votes[week][msg.sender].hasVoted = true;
    voters[week].push(msg.sender);
    votes[week][msg.sender].orgTo = id;
    votes[week][msg.sender].amount = msg.value;

    // update the votes for the organization that received the vote
    uint256 orgVotesCount = orgVotes[week][id];
    orgVotes[week][id] = orgVotesCount + msg.value;

    // update the winning organization if necessary
    uint256 winningOrgId = winningOrganizations[week];
    uint256 winningOrgVotesCount = orgVotes[week][winningOrgId];
    if (orgVotesCount + msg.value > winningOrgVotesCount) {
        winningOrganizations[week] = id;
    }
}

    mapping(uint256 => bool) public isExecuted;

    function execute(uint256 week) public {
    require(block.timestamp / 604800 > week, "Week has not passed.");
    require(voters[week].length > 0, "No voters.");
    require(!isExecuted[week], "This has already been executed.");
    isExecuted[week] = true;

    uint256 winningOrgId = winningOrganizations[week];
    require(Organizations[winningOrgId].class == 1, "Winning organization does not exist, or is not verified.");
    uint256 value_ = (weeklyFund) / 10;
    weeklyFund -= value_;
    require(address(this).balance >= value_, "Contract balance insufficient");
    payable(Organizations[winningOrgId].SendTo).transfer(value_);
}

    mapping(uint256 => mapping(address => bool)) claimed;

    function claimFTM(uint256 week) public {
        require(!claimed[week][msg.sender]);
        claimed[week][msg.sender] = true;
        uint256 value = votes[week][msg.sender].amount;
        require(address(this).balance >= value, "Contract balance insufficient");
        payable(msg.sender).transfer(value);
    }

    //Donate - Done

    function donate(uint256 id) public payable {
        require(msg.value > 0);
        require(Organizations[id].class != 3);
        payable(Organizations[id].SendTo).transfer(msg.value);
    }

    //Grants

    function requestGrant() public {}

    //Create Vote Lock -Unfinished

}
