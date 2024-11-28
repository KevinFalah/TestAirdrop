// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {BagelToken} from "src/BagelToken.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 public constant ROOT =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public constant AMOUNT_TO_SEND = 25 ether * 4;

    function deployMerkleAirdrop() public returns (MerkleAirdrop, BagelToken) {
        vm.startBroadcast();
        BagelToken token = new BagelToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(ROOT, token);
        token.mint(token.owner(), AMOUNT_TO_SEND);
        token.transfer(address(airdrop), AMOUNT_TO_SEND);
        vm.stopBroadcast();

        console.log("MerkleAirdrop deployed at:", address(airdrop));
        console.log("BagelToken deployed at:", address(token));
        return (airdrop, token);
    }

    function run() public returns (MerkleAirdrop, BagelToken) {
        return deployMerkleAirdrop();
    }
}
