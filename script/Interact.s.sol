pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {
    address constant CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant CLAIMING_AMOUNT = 25 * 1e18;
    bytes32 constant PROOF_1 = 0xa24ade2ae6f52f82ecae64070c08ae4a8e1fca2aeb44f468081ed6129559e7a8;
    bytes32 constant PROOF_2 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] proof = [PROOF_1, PROOF_2];
    bytes private signature = hex"cbd08ea4910eeb88f0fc9926bcccdc9400f17caffb6ce694e64ba7208af7fb35067e203a1e306fb860f43f36ac82c883362f86c5aff3a0c6aa1207baaec28d081b";

    error ClaimAirdropScript__InvalidSignature();

    function claimAirdrop(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        MerkleAirdrop(airdrop).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, proof, v, r, s);
        vm.stopBroadcast();
    }

    function splitSignature(bytes memory sig) public pure returns(uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert ClaimAirdropScript__InvalidSignature();
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function run() external {
        // address mostRecentDeployed = DevOpsTools.get_most_recent_deployment(
        //     "MerkleAirdrop",
        //     block.chainid
        // );
        address mostRecentDeployed = 0x19386214eE713B4A1609df4035085dDc829c4D1C;

        claimAirdrop(mostRecentDeployed);
    }
}
