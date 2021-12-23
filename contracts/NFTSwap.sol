//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTSwap is Ownable, ERC721Holder, ERC1155Holder {
  uint128 private _fee;
  uint128 private _feeLocked;

  // global swaps storage, id => swap
  mapping (uint256 => Swap) private _swaps;

  // NFT info, the contract address and NFT id
  struct NFT {
    address contractAddr;
    uint256 id;
  }

  // Both users are allowed to use NTFs and ETHs in the swap
  // Here we assume that user A is the one who create the swap
  struct Swap {
    // User A's swap information
    address payable aAddress;
    NFT[] aNFTs;
    uint128 aEth;

    // User B's swap information
    address payable bAddress;
    NFT[] bNFTs;
    uint128 bEth;
  }

  event FeeChange(int128 fee);
  // SwapCreate will be emitted when user A create a swap
  event SwapCreate(
    address indexed a,
    address indexed b,
    uint256 indexed id,
    NFT[] aNFTs,
    uint128 aEth
  );
  // SwapReady will be emitted when user B finish selecting his/her NFTs and ETHs to swap
  event SwapReady(
    address indexed a,
    address indexed b,
    uint256 indexed id,
    NFT[] aNFTs,
    uint128 aEth,
    NFT[] bNFTs,
    uint128 bEth
  );
  // SwapCancel will be emitted when either side cancel the swap
  event SwapCancel(
    address indexed a,
    address indexed b,
    uint256 indexed id
  );
  // SwapDone will be emitted when the swap is finished
  event SwapDone(
    address indexed a,
    address indexed b,
    uint256 indexed id
  );
}
