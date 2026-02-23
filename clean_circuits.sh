#!/bin/bash

set -e

CIRCUIT_DIR="./circuits"
CONTRACTS_DIR="./contracts"

echo "🧹 Cleaning circuit build artifacts in $CIRCUIT_DIR"

# Remove common circom/snarkjs outputs
rm -f "$CIRCUIT_DIR"/anchor.r1cs
rm -f "$CIRCUIT_DIR"/index.r1cs
rm -f "$CIRCUIT_DIR"/anchor.sym
rm -f "$CIRCUIT_DIR"/calldata.json

# # Remove Verifier.sol if it exists
# if [ -f "$CONTRACTS_DIR/Verifier.sol" ]; then
#     rm "$CONTRACTS_DIR/Verifier.sol"
# fi

# Optional: remove input.json (comment out if you want to keep it)
if [ -f "$CIRCUIT_DIR/input.json" ]; then
    rm "$CIRCUIT_DIR/input.json"
fi

# Remove snarkjs build directories if present
rm -rf "$CIRCUIT_DIR"/build
rm -rf "$CIRCUIT_DIR"/tmp
rm -rf "$CIRCUIT_DIR"/anchor_cpp
rm -rf "$CIRCUIT_DIR"/anchor_js
rm -rf "$CIRCUIT_DIR"/index_cpp
rm -rf "$CIRCUIT_DIR"/index_js

npx hardhat clean
npx hardhat compile

echo "✨ Circuits directory cleaned."
