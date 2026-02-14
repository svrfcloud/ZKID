#!/usr/bin/env node

const { ethers } = require("ethers");
const fs = require("fs");
const { spawn } = require("child_process");

async function deriveAnchorState() {
  provider = new ethers.JsonRpcProvider("http://localhost:8545");
  signer = await provider.getSigner();

  rawData = fs.readFileSync("./artifacts/contracts/IeNFT.sol/Connect.json");
  const { abi, bytecode } = JSON.parse(rawData, "utf-8");

  factory = new ethers.ContractFactory(abi, bytecode, signer);
  contract = await factory.deploy();
  await contract.waitForDeployment();

  apk = ethers.keccak256(ethers.toUtf8Bytes("anchorKey")); // Derive through an air-gap
  anchorWallet = new ethers.Wallet(apk, provider); // Otherwise private-key is exposed
  contractAddress = "0x3A220f351252089D385b29beca14e27F204c296A";

  tx = { to: anchorWallet.address, value: ethers.parseEther("1000.0") };
  await signer.sendTransaction(tx);
  anchorContract = new ethers.Contract(contractAddress, abi, anchorWallet);

  GENESIS_ANCHOR = ethers.keccak256(ethers.toUtf8Bytes("GENESIS_ANCHOR"));
  anchor = ethers.getAddress("0x" + GENESIS_ANCHOR.slice(-40));

  ZERO_STATE = ethers.keccak256(ethers.toUtf8Bytes("eNFT_ZERO_STATE"));

  logs = await provider.getLogs({ fromBlock: 0, toBlock: "latest" });
  nBlock = logs[0].blockNumber;
  receipt = await provider.getBlock(nBlock);
  τ = receipt.timestamp;

  const input = {
    index: 0,
    user: BigInt(anchor).toString(),
    timestamp: τ,
    zeroState: BigInt(ZERO_STATE).toString(),
  };

  fs.writeFileSync("./circuits/input.json", JSON.stringify(input, null, 2));

  const subprocess = spawn("bash", ["index1.sh"], {
    cwd: "./circuits"
    // stdio: ["pipe", "pipe", "pipe"],
  });

//   subprocess.stdout.on("data", (data) => {
//     const output = data.toString();
//     console.log("CIRCOM OUTPUT:", output);

//     if (output.includes("Enter circom filename")) {
//       subprocess.stdin.write("anchor\n");
//     }
//   });

  subprocess.stderr.on("data", (data) => {
    console.error(`CIRCOM ERROR: ${data}`);
  });

  subprocess.on("close", async (code) => {
    console.log(`Circuit generation exited with code ${code}`);
  });
}
deriveAnchorState().catch((error) => {
  console.error("Type: ", error);
  process.exit(1);
});
