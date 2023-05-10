//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract BlockcharityDistribution {
    uint256[] public values;
    address[] public recipients;
    uint256 public d;
    receive() external payable {
        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(address(this).balance * (values[i] / d));
        }
    }
    function changeDistribution(uint256[] memory values_, address[] memory recipients_, uint256 d_) external {
        require(msg.sender == owner);
        require(values_.length != 0);
        require(d != 0);
        require(values_.length == recipients_.length);
        uint256 total = 0;
        for (uint256 i = 0; i < values_.length; i++) {
            total += values_[i];
        }
        require(total == d_);
        values = values_;
        recipients = recipients_;
        d = d_;
    }

    address public owner;

    constructor(uint256[] memory values_, address[] memory recipients_, uint256 d_) {
        owner = msg.sender;
        require(values_.length != 0);
        require(d != 0);
        require(values_.length == recipients_.length);
        uint256 total = 0;
        for (uint256 i = 0; i < values_.length; i++) {
            total += values_[i];
        }
        require(total == d_);
        values = values_;
        recipients = recipients_;
        d = d_;
    }
}
