// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "src/MyGovernor.sol";
import {Box} from "src/Box.sol";
import {Timelock} from "src/Timelock.sol";
import {GovToken} from "src/GovToken.sol";

contract MyGovernorTest is Test {
    MyGovernor governor;
    Box box;
    Timelock timelock;
    GovToken govToken;

    address public USER = makeAddr("user");
    address public ADMIN = makeAddr("admin");
    uint256 public constant INITIAL_SUPPLY = 100 ether;
    uint256 public constant MIN_DELAY = 3600; // 1hour

    uint256 public constant VOTING_DELAY = 3600; // how long after proposal is created that voting can begin

    address[] proposers;
    address[] executors;

    uint256[] values;
    bytes[] calldatas;
    address[] targets;

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
        timelock.revokeRole(adminRole, USER); // user is the admin
        vm.stopPrank();

        box = new Box(0, address(timelock));

        // timelock owns the dao and the dao owns the tiimelock.
        // box is owned by the timelock.
        // timelock got the ultimate ownership of dao.
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        uint256 newValue = 42;
        box.store(newValue);
    }

    function testGovernanceUpdateBox() public {
        uint256 valueToStore = 888;
        string memory description = "store 888 in the box";
        bytes memory encodedFunctionCallData = abi.encodeWithSignature("store(uint256)", valueToStore);
        values.push(0); // value to send as ether
        calldatas.push(encodedFunctionCallData);
        targets.push(address(box));

        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // 2. view the state
        console.log("Proposal State:", uint256(governor.state(proposalId)));
        console.log(block.timestamp);

        vm.warp(block.timestamp + VOTING_DELAY + 1);
    }
}
