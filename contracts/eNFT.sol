//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract eNFT is ERC721 {
    uint40 public index;
    address constant anchor =
        address(uint160(uint256(keccak256("GENESIS_ANCHOR"))));
    bytes32 private constant ZERO_STATE = keccak256("eNFT_ZERO_STATE");

    bytes32 public merkleRoot;
    uint40 public leafCount;

    struct Users {
        address[] u;
    }

    mapping(uint40 => uint) public tau;
    mapping(address => bool) idOf;
    mapping(uint40 => bytes32) _state;

    mapping(uint40 => bytes32) public leaves;
    mapping(uint40 => bytes32) public nodes;

    event Genesis(bytes32 indexed state, bytes32 stateHash);

    modifier indexGenesis() {
        require(index == 0 && idOf[anchor] == false, "Contract anchored.");
        _;
    }

    modifier indexInitialized() {
        require(index > 0, "Anchor uninitialized.");
        _;
    }

    constructor() ERC721("eNFTid", "idNFT") {
        bootstrapContract();
        index++;
    }

    function bootstrapContract() internal indexGenesis {
        idOf[anchor] = true;
        uint t = block.timestamp;
        tau[index] = t;

        _state[index] = keccak256(
            abi.encodePacked(index, anchor, t, ZERO_STATE)
        );

        emit Genesis(_state[index], leaf());
    }

    function addUser(address _u) external virtual indexInitialized {}

    function loginUser(address _u) internal virtual returns (bool) {}

    function loginWrapper(
        address _u
    ) external virtual indexInitialized returns (bool) {}

    function leaf() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_state[index]));
    }
}

abstract contract ID is eNFT {
    function addUser(address _u) external override indexInitialized {
        require(idOf[anchor] == true, "Contract uninitialized.");
        require((idOf[_u] == false), "User Exists");
        idOf[_u] = true; // Sets user to active

        _safeMint(_u, index); // Mints the NFTid to the user

        uint t = block.timestamp;
        tau[index] = t;

        _state[index] = keccak256(
            abi.encodePacked(index, _u, t, _state[index - 1])
        );
        recordLeaf(index, leaf());
        index++;
    }

    function recordLeaf(uint40 i, bytes32 leafHash) internal {
        leaves[i] = leafHash;
        leafCount++;
    }

    function loginUser(address _u) internal virtual override returns (bool) {
        require(idOf[_u] == true, "Invalid User");
        return idOf[_u];
    }

    function loginWrapper(
        address _u
    ) external override indexInitialized returns (bool) {
        return loginUser(_u);
    }
}
