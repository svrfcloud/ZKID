#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ──────────────────────────────────────────────────────────────────────────────
CIRCUITS_DIR=~/ZKID/circuits
CONTRACTS_DIR=~/ZKID/contracts

# ──────────────────────────────────────────────────────────────────────────────
# 1. Read & compile the Circom circuit
# ──────────────────────────────────────────────────────────────────────────────
read -p "Enter circom filename (without .circom): " CIRCUIT

CIRCUIT_PATH="${CIRCUITS_DIR}/${CIRCUIT}.circom"
if [[ ! -f "$CIRCUIT_PATH" ]]; then
  echo "Error: '$CIRCUIT_PATH' not found."
  exit 1
fi

echo "📐 Compiling ${CIRCUIT}.circom…"
cd "$CIRCUITS_DIR"
circom "$CIRCUIT.circom" --r1cs --wasm --sym --c
echo "✔️  R1CS, WASM, C code, and symbols generated."

# ──────────────────────────────────────────────────────────────────────────────
# 2. Build & run the witness generator
# ──────────────────────────────────────────────────────────────────────────────
WITNESS_CPP_DIR="${CIRCUITS_DIR}/${CIRCUIT}_cpp"
EXECUTABLE="${WITNESS_CPP_DIR}/${CIRCUIT}"
INPUT_JSON="${CIRCUITS_DIR}/input.json"
WITNESS_FILE="${WITNESS_CPP_DIR}/witness.wtns"

echo "🛠️  Building C++ witness generator…"
cd "$WITNESS_CPP_DIR"
make

echo "🔢 Generating the witness…"
"$EXECUTABLE" "$INPUT_JSON" "witness.wtns"
if [[ ! -f "$WITNESS_FILE" ]]; then
  echo "Error: witness.wtns not created."
  exit 1
fi
echo "✔️  Witness generated at $WITNESS_FILE."

# ──────────────────────────────────────────────────────────────────────────────
# 3. Determine minimal Powers-of-Tau size
# ──────────────────────────────────────────────────────────────────────────────
R1CS_FILE="${CIRCUITS_DIR}/${CIRCUIT}.r1cs"
CONSTRAINTS=$(snarkjs r1cs info "$R1CS_FILE" | grep 'Constraints:' | awk '{print $6}')
NEEDED=$(( CONSTRAINTS * 2 ))

POWTAU=0
while (( (1 << POWTAU) < NEEDED )); do
  POWTAU=$(( POWTAU + 1 ))
done
let "PTAU_SIZE = 1 << POWTAU"


echo "🔢 Constraints: $CONSTRAINTS; need 2× → $NEEDED."
echo "🎯 Selecting Powers-of-Tau of size 2^$POWTAU = $PTAU_SIZE."

# ──────────────────────────────────────────────────────────────────────────────
# 4. Run the Powers-of-Tau ceremony
# ──────────────────────────────────────────────────────────────────────────────
JS_DIR="${CIRCUITS_DIR}/${CIRCUIT}_js"
cd "$JS_DIR"

POT0="pot_${PTAU_SIZE}_0000.ptau"
POT1="pot_${PTAU_SIZE}_0001.ptau"
POT_FINAL="pot_${PTAU_SIZE}_final.ptau"

echo "⚙️  Initializing Powers-of-Tau (bn128, size $PTAU_SIZE)…"
snarkjs powersoftau new bn128 $POWTAU $POT0 -v

echo "⚙️  Contributing to Powers-of-Tau…"
snarkjs powersoftau contribute $POT0 $POT1 --name="First contributor" -v

echo "⚙️  Preparing Phase 2…"
snarkjs powersoftau prepare phase2 $POT1 $POT_FINAL -v

# ──────────────────────────────────────────────────────────────────────────────
# 5. Groth16 setup & ZKey contributions
# ──────────────────────────────────────────────────────────────────────────────
ZKEY0="${CIRCUIT}_0000.zkey"
ZKEY1="${CIRCUIT}_0001.zkey"
FINAL_ZKEY="${CIRCUIT}_final.zkey"

echo "🛠️  Groth16 setup…"
snarkjs groth16 setup "$R1CS_FILE" "$POT_FINAL" "$ZKEY0"

echo "🔐 First ZKey contribution…"
snarkjs zkey contribute "$ZKEY0" "$ZKEY1" \
  --name="Trusted Contributor #1" -v

echo "🔔 Applying beacon (optional)…"
snarkjs zkey beacon \
  "$ZKEY1" "$FINAL_ZKEY" \
  0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef \
  10 \
  --name="Final Beacon" -v

# ──────────────────────────────────────────────────────────────────────────────
# 6. Export verification key & generate proofs
# ──────────────────────────────────────────────────────────────────────────────
echo "🗝️  Exporting verification key…"
snarkjs zkey export verificationkey "$FINAL_ZKEY" verification_key.json

echo "📝 Proving…"
snarkjs groth16 prove "$FINAL_ZKEY" "$WITNESS_FILE" proof.json public.json

echo "🔍 Verifying…"
snarkjs groth16 verify verification_key.json public.json proof.json

# ──────────────────────────────────────────────────────────────────────────────
# 7. Generate Solidity verifier & calldata
# ──────────────────────────────────────────────────────────────────────────────
echo "📜 Generating Solidity verifier…"
snarkjs zkey export solidityverifier "$FINAL_ZKEY" "$CONTRACTS_DIR/Verifier.sol"

echo "📦 Exporting calldata for on‐chain…"
snarkjs zkey export soliditycalldata public.json proof.json \
  | sed '1s/^/[/; $s/$/]/' \
  > "${CIRCUITS_DIR}/calldata.json"

# ──────────────────────────────────────────────────────────────────────────────
# 8. Clean & compile smart contracts
# ──────────────────────────────────────────────────────────────────────────────
cd "$CIRCUITS_DIR"
npx hardhat clean
npx hardhat compile

echo "🎉 All done. Your circuit is compiled, proved, verified, and the verifier is generated."