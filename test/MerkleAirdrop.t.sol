// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {BagelToken} from "src/BagelToken.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "script/DeployMerkleAirdrop.s.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    BagelToken token;
    MerkleAirdrop airdrop;
    address gasPayer;
    address user;
    uint256 userPrivateKey;
    uint256 public constant AMOUNT_TO_CLAIM = 25 ether; // 25 * 1e18
    uint256 public constant AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;
    bytes32 public constant ROOT =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    bytes32 proofOne =
        0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo =
        0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public proofs = [proofOne, proofTwo];

    function setUp() public {
        
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.deployMerkleAirdrop();
        } else {
            token = new BagelToken();
            airdrop = new MerkleAirdrop(ROOT, token);
            token.mint(token.owner(), AMOUNT_TO_SEND);
            token.transfer(address(airdrop), AMOUNT_TO_SEND);
        }

        (user, userPrivateKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    function testUserCanClaim() public {
        bytes32 digest = airdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        vm.prank(gasPayer);
        airdrop.claim(user, AMOUNT_TO_CLAIM, proofs, v, r, s);

        uint256 endingBalances = token.balanceOf(user);
        assert(endingBalances == AMOUNT_TO_CLAIM);
    }

    function testGetMerkleRoot() public {
        bytes32 actualRoot = airdrop.getMerkleRoot();
        assertEq(actualRoot, ROOT);
    }
}
