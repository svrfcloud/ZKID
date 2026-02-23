#!/bin/bash

# Check if the circom file exists and run the compiler to create files and directories
echo "Enter circom filename to start the compiler."
read circomFile

filePath=~/ZKID/circuits
circomFilePath="${filePath}/${circomFile}.circom"

if [[ ! -f $circomFilePath ]]; then
    echo "File does not exist."
    echo "Please enter a valid circom filename."
    read circomFile
    filePath=~/ZKID/circuits
    circomFilePath=${filePath}/${circomFile}.circom
elif [[ -f "$circomFilePath" ]]; then
    cd $filePath
    circom $circomFilePath --r1cs --wasm --sym --c
fi

# Generate the witness file
executable="./${circomFile}"
inputPath="${filePath}/input.json"
cppDir="${filePath}/${circomFile}_cpp"

cd $cppDir
make
$executable $inputPath witness.wtns || { echo  "Compilation failed."; exit 1;}

witnessDir=$cppDir/witness.wtns

if [[ ! -f "$witnessDir" ]]; then
    echo "Witness file missing."
    exit 1
fi

jsDir="${filePath}/${circomFile}_js"
# Enter javascript directory for the Powers of Tau ceremony
cd $jsDir

# Powers of Tau
echo "How many Powers of Tau? (1-28)"
read powTau

if [[ $powTau -ge 1 && $powTau -le 28 ]]; then
    snarkjs powersoftau new bn128 $powTau pot_0000.ptau -v
    snarkjs powersoftau contribute pot_0000.ptau pot_0001.ptau --name="First contributor" -v
    snarkjs powersoftau prepare phase2 pot_0001.ptau pot_final.ptau -v
elif [[ $powTau -lt 1 || $powTau -gt 28 ]]; then
    echo "Please enter an integer equal to at least one and at most twenty-eight"
    read powTau
fi 

r1csFile="${filePath}/${circomFile}.r1cs"
zKey0="${circomFile}_0000.zkey"
zKey1="${circomFile}_0001.zkey"

snarkjs groth16 setup $r1csFile pot_final.ptau $zKey0
snarkjs zkey contribute $zKey0 $zKey1 --name="1st Contribution Name" -v
snarkjs zkey export verificationkey $zKey1 verification_key.json


snarkjs groth16 prove $zKey1 $witnessDir proof.json public.json
snarkjs groth16 verify verification_key.json public.json proof.json

# Generate the Solidity verifier contract

contractPath=~/ZKID/contracts

snarkjs zkey export solidityverifier $zKey1 ${contractPath}/Verifier.sol
snarkjs zkey export soliditycalldata public.json proof.json \
  | sed '1s/^/[/; $s/$/]/' \
  > ~/ZKID/circuits/calldata.json

cd $filePath
npx hardhat clean
npx hardhat compile