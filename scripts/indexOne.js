#!/usr/bin env node

const { ethers } = require("ethers");
const fs = require("fs");
const { spawn } = require("child_process");

async function fetchTime() {
  provider = new ethers.JsonRpcProvider("http://localhost:8545");

  rawState = fs.readFileSync("../circuits/anchor_js/public.json", "utf-8");
  parseState = JSON.parse(rawState);
  S_0 = parseState[0];

  logs = await provider.getLogs({ fromBlock: 0, toBlock: "latest" });
  nBlock = (logs[1]).blockNumber;
  receipt = await provider.getBlock(nBlock);
  τ = receipt.timestamp;
  x = (logs[1]).topics[2];
  y = x.slice(-40);
  client = "0x" + y;

  const input = {
    index: 1,
    user: BigInt(client).toString(),
    timestamp: τ,
    previousState: S_0,
  };

  fs.writeFileSync("../circuits/input1.json", JSON.stringify(input, null, 2));

  const subprocess = spawn("bash", ["../circuits/index1.sh"]);
  const circomFileName = "anchor\n"; // change to index
  const powersOfTau = "12\n";
  const entropy1 = "User1\n";
  const entropy2 = "S_0\n";

  subprocess.stdout.on("data", (data) => {
    const output = data.toString();

    if (output.includes("Enter circom filename to start the compiler.")) {
      subprocess.stdin.write(circomFileName);
    } else if (output.includes("How many")) {
      subprocess.stdin.write(powersOfTau);
    } else if (output.includes("Enter a random text")) {
      subprocess.stdin.write(entropy1);
    } else if (output.includes("Entropy")) {
      subprocess.stdin.write(entropy2);
    }
  });

  subprocess.stderr.on("data", (data) => {
    console.error(`stderr: ${data}`);
  });

  subprocess.on("close", async (code) => {
    console.log(`Circuit generation exited with code ${code}`);
  });
}
fetchTime().catch((error) => {
  console.error("Log:", error);
});
