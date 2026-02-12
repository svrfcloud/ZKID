//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./eNFT.sol";

interface IeNFT {
    function addUser(address _u) external;
}

contract Connect is ID {
    function connectUser(address _to, address _contract) external {
        IeNFT(_contract).addUser(_to);
    }
}
