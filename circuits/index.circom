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

template ChainN(n) {
    signal input index[n];
    signal input user[n];
    signal input timestamp[n];
    signal input genesisState; // check if currentState output from above
    
    signal output intermediateState[n];
    signal output finalState;
    
    // An array of subcomponent s
    component step[n];
    var priorState = genesisState;
    
    for( var i = 0; i< n; i++) {
        step[i] = InclusionProof();
        step[i].index <== index[i];
        step[i].user <== user[i];
        step[i].timestamp <== timestamp[i];
        step[i].zeroState <== priorState;
        
        intermediateState[i] <== step[i].currentState;
        // priorState <== intermediateState[i];
    }
    
    finalState <== priorState;
}

component main = ChainN(16);