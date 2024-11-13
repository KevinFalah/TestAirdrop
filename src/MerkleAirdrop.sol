// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is ReentrancyGuard, EIP712 {
    using SafeERC20 for IERC20;
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    bytes32 private constant MESSAGE_TYPEHASH =
        keccak256("AirdropClaim(address account, uint256 amount)");

    mapping(address claimer => bool hasClaimed) private s_hasClaimed;

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    event Claim(address indexed account, uint256 amount);

    //! FUNCTIONS
    constructor(
        bytes32 merkleRoot,
        IERC20 airdropToken
    ) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        if (
            !_isValidSignature(
                account,
                getMessageHash(account, amount),
                v,
                r,
                s
            )
        ) {
            revert MerkleAirdrop__InvalidSignature();
        }

        //! Calculate using acount and amount, the hash -> leaf node
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(account, amount)))
        );
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
        s_hasClaimed[account] = true;
    }

    function getMessageHash(
        address account,
        uint256 amount
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        MESSAGE_TYPEHASH,
                        AirdropClaim({account: account, amount: amount})
                    )
                )
            );
    }

    //! VIEW AND PURE
    function getMerkleRoot() public view returns(bytes32) {
        return i_merkleRoot;
    }
    function getAirdropToken() public view returns(IERC20) {
        return i_airdropToken;
    }

    //! INTERNAL FUNCTIONS

    //* verify whether the recovered signer is the expected signer/the account to airdrop tokens for
    function _isValidSignature(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        (address actualSigner, , ) = ECDSA.tryRecover(digest, v, r, s);

        return actualSigner == signer;
    }
}
