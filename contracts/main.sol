// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract Blockcharity {
    //Tracking of donations
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

    struct Organization {
        address SendTo;
        uint256 ftmGathered;
        uint256 id;
        string website;
        string name;
    }

    Organization[] public organizations;

    function getOrganizations() public view returns(Organization[] memory) {
        return(organizations);
    }
    function getUnregisteredOrganizations() public view returns(Organization[] memory) {
        return(unregisteredOrganizations);
    }

    struct Proposal {
        uint256 outcome;
    }
    struct Vote {
        bool hasVoted; //
        uint256 orgTo; //
        uint256 amount;
    }

    mapping(uint256 => mapping(uint256 => uint256)) public orgVotes; //
    mapping(uint256 => mapping(address => Vote)) public votes; //
    mapping(uint256 => address[]) public voters; //
    mapping(uint256 => Proposal) public proposals; //
    
    function getVoters(uint256 week) public view returns(address[] memory) {
        return(voters[week]); //this value cannot be retrieved unless individually
    }

    mapping(address => bool) staff;

    modifier isStaff() {
        require(staff[msg.sender] == true, "This function is locked.");
        _;
    }

    function addStaff(address newStaff) external {
        require(msg.sender == owner, "This function is locked.");
        staff[newStaff] = true;
    }

    constructor() {
        owner = msg.sender;
        staff[msg.sender] = true;
    }


    function registerOrganization(string memory website, address sendTo, string memory name) public payable {
         unregisteredOrganizations.push(Organization(sendTo, 0, 0, website, name));
    }

    Organization[] public unregisteredOrganizations;

    function denyOrganization(uint256 index) isStaff external {
        Organization memory lastValue = unregisteredOrganizations[unregisteredOrganizations.length - 1];
        unregisteredOrganizations[index] = lastValue;
        unregisteredOrganizations.pop();
    }

    function verifyOrganization(uint256 index) isStaff external {
        require(unregisteredOrganizations[index].id == 0);
        unregisteredOrganizations[index].id = organizations.length;
        organizations.push(unregisteredOrganizations[index]);
        Organization memory lastValue = unregisteredOrganizations[unregisteredOrganizations.length - 1];
        unregisteredOrganizations[index] = lastValue;
        unregisteredOrganizations.pop();
        
    }

    function vote(uint256 organization) external payable {
        uint256 week = block.timestamp/604800;
        require(msg.value > 0, "Insufficient value");
        require(organizations[organization].SendTo != address(0x0), "That organization does not exist."); //make sure organization exists
        require(votes[week][msg.sender].hasVoted == false, "You have already voted."); //make sure has not voted
        votes[week][msg.sender].hasVoted = true;
        voters[week].push(msg.sender);
        votes[week][msg.sender].orgTo = organization;
        votes[week][msg.sender].amount = msg.value;
        orgVotes[week][organization] += msg.value;
        }

    mapping(uint256 => bool) public isExecuted;

    function execute(uint256 week) public {
        require(block.timestamp/604800 > week, "Week has not passed."); 
        require(voters[week].length > 0, "No voters.");
        require(!isExecuted[week], "This has already been executed."); 
        isExecuted[week] = true;
        uint256 winningOrganization = 0;
        for (uint256 i = 0; i < organizations.length; i++) {
            if (orgVotes[week][i] > orgVotes[week][winningOrganization]) {
            winningOrganization = i;
        }
        }
        for (uint256 i = 0; i < voters[week].length; i++) {
            address addr = voters[week][i];
            uint256 value = votes[week][addr].amount;
            require(address(this).balance >= value, "Contract balance insufficient");
            payable(addr).transfer(value);
        }
        uint256 value_ = (address(this).balance * 9)/10;
        require(address(this).balance >= value_, "Contract balance insufficient");
        payable(organizations[winningOrganization].SendTo).transfer(value_);
        
    }
}
