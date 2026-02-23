import { ethers } from "https://cdnjs.cloudflare.com/ajax/libs/ethers/6.7.0/ethers.min.js";

async function index() {
  document.getElementById("Signup").addEventListener("click", async () => {
    let signupQuery = document.getElementById("inputSignup").value.trim();

    // Strip quotes if user types them
    signupQuery = signupQuery.replace(/^['"]+|['"]+$/g, "");

    if (!ethers.isAddress(signupQuery.toString())) {
      return alert("Invalid address");
    }

    try {
      let provider = new ethers.JsonRpcProvider("http://localhost:8545");
      const apk = ethers.keccak256(ethers.toUtf8Bytes("anchorKey"));
      const anchorWallet = new ethers.Wallet(apk, provider);

      const response = await fetch(
        "./Connect.json",
      );
      const responseJSON = await response.json();
      const abi = responseJSON.abi;

      const contractAddress = "0x3A220f351252089D385b29beca14e27F204c296A";
      const contract = new ethers.Contract(contractAddress, abi, anchorWallet);

      const addUser = await contract.connectUser(signupQuery, contractAddress);
      if (addUser) alert("Successful");
    } catch (err) {
      console.error("Signup failed:", err);
      alert("Signup failed");
    }
  });

  document.getElementById("Login").addEventListener("click", async () => {
    const loginQuery = document.getElementById("inputLogin").value.trim();
    if (!loginQuery) return alert("Please enter a valid ID");

    try {
      const response = await fetch("./IDwithZK.json");
      const responseJSON = await response.json();
      const abi = responseJSON.abi;

      const login = await contract.userLogin(loginQuery);
      if (login) {
        console.log(login);
        window.location.href = `homepage.html?query=${encodeURIComponent(
          loginQuery,
        )}`;
      }
    } catch (err) {
      console.error("Login failed:", err);
      alert("Login failed");
    }
  });
}

index().catch(console.error);
