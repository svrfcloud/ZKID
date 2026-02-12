//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Verifier.sol";

interface IVerifier {
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory pubSignals
    ) external view returns (bool);
}

contract IDwithZK {
    IVerifier public verifier;

    mapping(address => bool) public verifiedUsers;
    mapping(bytes32 => bool) public nullifier;

    constructor(address _verifierAddress) {
        verifier = IVerifier(_verifierAddress);
    }

    event UserLogin(address _owner, bytes32 nullifier);

    function loginWithZKP(
        uint[2] memory _a,
        uint[2][2] memory _b,
        uint[2] memory _c,
        uint[1] memory _pubSignals
    ) public {
        bytes32 flip = bytes32(_pubSignals[0]);
        // require(!nollie[flip], "Nullifier used");
        require(verifier.verifyProof(_a, _b, _c, _pubSignals), "Invalid Proof");
        // nollie[flip] = true;
        verifiedUsers[msg.sender] = true;
        emit UserLogin(msg.sender, flip);
    }
}
