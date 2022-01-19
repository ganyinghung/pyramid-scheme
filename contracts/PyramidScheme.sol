// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/** 
 * @title PyramidScheme
 * @dev Implements an automatic pyramid scheme, aka Ponzi scheme, with smart contract
 */
contract PyramidScheme is Ownable {

    mapping(address => address) public recuriterOf;
    mapping(address => uint) public depthOf; 

    event NewMemberJoined(address newMember, address theRecruiter);

    function join() public payable {
        // if no recruiter is specified, set it as the owner
        join(owner());
    }

    function join(address recruiter) public payable {
        // must input at least 0.005 eth
        require(msg.value >= 5000000000000000, "You must pay at least 0.005 eth.");

        // make sure msg.sender hasn't joined yet
        require(recuriterOf[msg.sender] == address(0), "You have already joined the scheme.");

        // owner cannot join
        require(msg.sender != owner(), "Owner of this contract cannot join.");

        // make sure either recruiter has joined already, or is the contract owner
        require(recruiter == owner() || recuriterOf[recruiter] != address(0), "Your recruiter has not joined the scheme yet.");

        recuriterOf[msg.sender] = recruiter;
        uint myDepth = depthOf[recruiter] + 1;
        depthOf[msg.sender] = myDepth;

        // find out all the recruiters upstream
        address[] memory ancestors = new address[](myDepth);
        uint i = 0;

        ancestors[i] = recruiter; 
        console.log("Ancestor: ", recruiter);
        while (recuriterOf[recruiter] != address(0) && ++i < myDepth) {
            recruiter = recuriterOf[recruiter];
            ancestors[i] = recruiter;
            console.log("Ancestor found: ", recruiter);
        }

        // and pay them
        if (myDepth == 1) {
            // 100% to the owner
            payable(owner()).transfer(msg.value);
        }
        if (myDepth == 2) {
            // 50% to immediate recruiter, 50% to owner
            payable(ancestors[0]).transfer(msg.value / 2);
            payable(ancestors[1]).transfer(msg.value / 2);
        }
        if (myDepth >= 3) {
            // 50% to immediate recruiter, 30% to one level up, 20% to all the rest (combined)
            payable(ancestors[0]).transfer(msg.value / 2);
            payable(ancestors[1]).transfer(msg.value * 3 / 10);
            for (uint j = 2; j < myDepth; j++) {
                payable(ancestors[j]).transfer(msg.value / (5*(myDepth-2)));
            }
        }

        // finally emit the event
        emit NewMemberJoined(msg.sender, ancestors[0]);

    }

}