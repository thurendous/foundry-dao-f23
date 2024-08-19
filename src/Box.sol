// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
    uint256 private s_number;

    // Emitted when the stored number changes
    event NumberChanged(uint256 number);

    constructor(uint256 initialValue, address initialOwner) Ownable(initialOwner) {
        s_number = initialValue;
    }

    // Stores a new number in the contract
    function store(uint256 newValue) public onlyOwner {
        s_number = newValue;
        emit NumberChanged(newValue);
    }

    // Reads the last stored number
    function getNumber() public view returns (uint256) {
        return s_number;
    }
}
