pragma circom 2.0.0;

include "./circomlib/circuits/poseidon.circom";

template InclusionProof() {
    signal input index;
    signal input user;
    signal input timestamp;
    signal input zeroState;
    signal output currentState;
    
    component poseidon = Poseidon(4);
    poseidon.inputs[0] <== index;
    poseidon.inputs[1] <== user;
    poseidon.inputs[2] <== timestamp;
    poseidon.inputs[3] <== zeroState;
    currentState <== poseidon.out;
}

component main = InclusionProof();