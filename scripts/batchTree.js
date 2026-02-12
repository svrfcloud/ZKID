const { ethers } = require("ethers");
const circomlibjs = require("circomlibjs");
const fs = require("fs");

async function batch() {
    const poseidonLib = await circomlibjs.buildPoseidon();
    const F = poseidonLib.F;

    // Constants
    const anchorHash = ethers.keccak256(ethers.toUtf8Bytes("GENESIS_ANCHOR"));
    const u0 = ethers.getAddress("0x" + anchorHash.slice(-40));
    const ZERO_STATE = BigInt(ethers.keccak256(ethers.toUtf8Bytes("eNFT_ZERO_STATE")));
    const genesisTimestamp = 1751983736;

    // Initial input
    const inputStates = [];

    const initialInput = {
        index: 0,
        user: BigInt(u0).toString(),
        timestamp: genesisTimestamp,
        previousState: ZERO_STATE.toString()
    };

    inputStates.push(initialInput);

    // Generate wallets
    const wallets = Array.from({ length: 15 }, () => ethers.Wallet.createRandom());

    // Generate timestamps (every 60 seconds after genesis)
    const timestamps = Array.from({ length: 15 }, (_, i) => genesisTimestamp + (i + 1) * 60);

    // Loop to build Poseidon input chain
    for (let i = 1; i <= 15; i++) {
        const prev = inputStates[i - 1];

        const poseidonInput = [
            BigInt(prev.index),
            BigInt(prev.user),
            BigInt(prev.timestamp),
            BigInt(prev.previousState)
        ];

        const hashedState = F.toString(poseidonLib(poseidonInput));

        const currentInput = {
            index: i,
            user: BigInt(wallets[i - 1].address).toString(),
            timestamp: timestamps[i - 1],
            previousState: BigInt(hashedState).toString()
        };

        inputStates.push(currentInput);
    }

    // Format output for Circom input.json
    console.log(JSON.stringify(inputStates, null, 2));

    const structuredInput = {
        index: inputStates.map(x => x.index),
        user: inputStates.map(x => x.user.toString()), // Ensure BigInt as string
        timestamp: inputStates.map(x => x.timestamp),
        genesisState: inputStates[0].previousState.toString()
    };

    fs.writeFileSync("input.json", JSON.stringify(structuredInput, null, 2));

    console.log(structuredInput);

}

batch().catch(console.error);
