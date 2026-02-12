# **ZKID — Zero‑Knowledge Identity NFTs**

ZKID is a minimal, end‑to‑end identity system that binds an Ethereum address to a verifiable, hash‑chained state commitment. Each identity is represented as an ERC‑721 token (“eNFT”), and users can authenticate using a zero‑knowledge proof rather than exposing private data or relying on centralized sign‑in flows.

ZKID combines:

- **Solidity contracts** for identity minting and state commitments  
- **Poseidon‑based Circom circuits** for proving inclusion in the identity chain  
- **Groth16 verification** on‑chain  
- **A simple front‑end** for signup and ZK‑based login  
- **Off‑chain scripts** for generating witness data and proofs  

The result is a compact, auditable identity primitive suitable for decentralized apps, attestations, and privacy‑preserving authentication.

---

## **📦 Repository Structure**

```
ZKID/
│
├── contracts/
│   ├── eNFT.sol          # Base identity NFT + state chain
│   ├── IeNFT.sol         # Interface + Connect helper
│   ├── IDwithZK.sol      # ZK-enabled login wrapper (Groth16)
│   ├── Poseidon.sol      # Poseidon hash (Solidity)
│   └── Verifier.sol      # Groth16 verifier
│
├── circuits/
│   ├── index.circom      # Inclusion + chain circuit (Poseidon)
│   ├── input.json        # Example witness input
│   ├── index.wasm        # Compiled circuit
│   └── index_final.zkey  # Proving key
│
├── scripts/
│   ├── deployer.js       # Deploy contract + derive genesis state
│   └── batchTree.js      # Build Poseidon state chain off-chain
│
└── frontend/
    ├── index.html        # Signup + login UI
    ├── index.css         # Styling
    ├── proxyscript.js    # Front-end logic (signup + zkLogin)
    ├── Connect.json      # ABI
    └── IDwithZK.json     # ABI
```

---

## **🔐 Identity Model**

Each identity is represented as an NFT minted to the user’s address.  
The contract maintains a **hash‑chained state**, where each new identity extends the chain:

\[
state_i = Poseidon(index_i,\ user_i,\ timestamp_i,\ state_{i-1})
\]

This produces:

- A deterministic, append‑only identity log  
- A ZK‑friendly commitment (Poseidon)  
- A leaf hash for Merkle‑tree extensions (future work)

The contract stores:

- `idOf[address]` — whether an address is registered  
- `_state[index]` — the Poseidon state chain  
- `leaves[index]` — leaf commitments  
- `tau[index]` — timestamps  

---

## **🧩 Circom Circuit**

The circuit mirrors the contract’s state transition logic.

### **InclusionProof**
Computes a single Poseidon transition:

```
Poseidon(index, user, timestamp, previousState)
```

### **ChainN(n)**
Chains `n` transitions to produce a final state:

```
state_0 = genesisState
state_i = InclusionProof(index[i], user[i], timestamp[i], state_[i-1])
```

The final output (`finalState`) is compared on‑chain to the contract’s stored state.

---

## **🛡️ Zero‑Knowledge Login**

ZKID provides a privacy‑preserving login flow:

1. User enters their Ethereum address  
2. Front‑end builds the witness (index, user, timestamps, genesisState)  
3. Circom generates a Groth16 proof  
4. The proof is submitted to the contract  
5. The contract verifies:
   - The proof is valid  
   - The public signals match the on‑chain state  
   - The caller is the owner of the identity  

This enables login without revealing:

- Private keys  
- Secrets  
- Historical identity data  
- Any part of the witness  

---

## **🖥️ Front-End Flow**

### **Signup**
- User enters an address  
- The “anchor” wallet calls `Connect.connectUser`  
- The identity NFT is minted  
- The state chain is extended  

### **Login**
- User enters their address  
- Front-end generates a ZK proof using snarkjs  
- Calls `zkLogin(address, proof, publicSignals)`  
- On success, the user is authenticated  

---

## **🛠️ Off‑Chain Tools**

### **deployer.js**
- Deploys the contract  
- Reconstructs the genesis state  
- Writes `input.json` for the circuit  
- Automates the proving key ceremony (via `index1.sh`)  

### **batchTree.js**
- Generates a synthetic chain of 16 identities  
- Computes Poseidon transitions  
- Produces a full witness input for testing  

---

## **🚀 Getting Started**

### **Install dependencies**
```
npm install
```

### **Compile circuits**
```
bash ./index1.sh
```

### **Deploy contracts**
```
node scripts/deployer.js
```

### **Run the front-end**
Serve the `frontend/` directory with any static server:

```
npx http-server
```

---

## **📚 Roadmap**

- [ ] Replace Keccak with Poseidon fully on-chain  
- [ ] Create symbolic links for ABI (front/Connect.json -> artifacts, IDwithZK.json -> artifacts)
- [ ] Add Merkle tree + incremental root updates  
- [ ] Add revocation / rotation semantics  
- [ ] Add DID‑compatible metadata  
- [ ] Add attestation registry  
- [ ] Add wallet‑less login (session keys)
- [ ] Develop the DAO anchor deployment contract for constellation arcs (FIFO - Federated Identity Families On-Chain)
- [ ] Replace the static front-end with a dynamic state dApp
- [ ] Add GraphQL APIs for query, mutations, and subscription oracles (verifiable analytics)
- [ ] Test secuirty functionality of subscription oracle pricing and arbitrage opportunity with MEV (autonomous governance)

---

## **🤝 Contributing**

ZKID is early-stage and intentionally minimal.  
PRs, issues, and discussions are welcome — especially around:

- Circuit design  
- State commitment schemes  
- Security analysis  
- Front-end UX  
- Documentation  

---