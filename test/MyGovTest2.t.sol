// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "src/MyGovernor.sol";
import {Timelock} from "src/Timelock.sol";
import {GovToken} from "src/GovToken.sol";
import {Box} from "src/Box.sol";

contract MyGovernorTest2 is Test {
    MyGovernor public governor;
    Box box;
    Timelock timelock;
    GovToken govToken;

    address public USER = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 100 ether;
    uint256 public constant MIN_DELAY = 3600; // 1hour
    uint256 public constant VOTING_DELAY = 1 days; // How many time till a proposal vote becomes active
    uint256 public constant VOTING_PERIOD = 1 weeks;

    address[] proposers;
    address[] executors;

    // for the proposal
    address[] targets;
    uint256[] values;
    bytes[] calldatas;

    function setUp() public {
        govToken = new GovToken();
        govToken.mint(USER, INITIAL_SUPPLY);

        vm.startPrank(USER);
        govToken.delegate(USER);

        timelock = new Timelock(MIN_DELAY, proposers, executors, USER); // empty array means anyone can propose and anyone can execute

        governor = new MyGovernor(govToken, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE(); // keccak256("PROPOSER_ROLE")
        bytes32 executorRole = timelock.EXECUTOR_ROLE(); // keccak256("EXECUTOR_ROLE")
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE(); // keccak256("DEFAULT_ADMIN_ROLE")

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0)); // anybody can execute the proposal, this should not be done in production
        timelock.revokeRole(adminRole, USER); // user is the admin and we do not need a single pointo of failure
        vm.stopPrank();

        box = new Box(0, address(timelock));
        // box.transferOwnership(address(timelock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        uint256 newValue = 42;
        vm.expectRevert();
        box.store(newValue);
    }

    function testGovernanceUpdateBox() public {
        uint256 newValue = 888;
        string memory description = "store 888 in box";
        bytes memory encodeFunctionData = abi.encodeWithSignature("store(uint256)", newValue);
        values.push(0);
        targets.push(address(box));
        calldatas.push(encodeFunctionData);

        // 1. propose to the dao
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // view the state
        uint256 state = uint256(governor.state(proposalId));
        console.log("state1", state);

        // time lasts
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + 1 + 1);

        uint256 state2 = uint256(governor.state(proposalId));
        console.log("state2", state2);

        // 2. vote
        string memory reason = "cuz blue frog is cool";
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, 1, reason);

        // 3. queue
        // time lasts
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + 50400 + 1);
        uint256 state3 = uint256(governor.state(proposalId));
        console.log("state3", state3);

        // 3. Queue the TX
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        // view state
        uint256 state4 = uint256(governor.state(proposalId));
        console.log("state4", state4);

        // bytes32 hashedId = timelock.hashOperationBatch(targets, values, calldatas, predecessor, salt);
        // console.log("timestamp:", timelock.getTimestamp(hashedId));
        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);

        // 4. execute
        governor.execute(targets, values, calldatas, descriptionHash);

        console.log("box value", box.getNumber());
        assertEq(box.getNumber(), newValue);
    }
}
