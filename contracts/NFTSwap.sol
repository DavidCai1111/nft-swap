//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTSwap is Ownable, ERC721Holder, ERC1155Holder {
  uint256 private _fee;
  uint256 private _ethLocked;

  // global swaps storage, id => swap
  uint256 private _swapIdx;
  mapping (uint256 => Swap) private _swaps;

  // NFT info, the contract address and NFT id
  struct NFT {
    address contractAddr;
    uint256 id;
    uint256 amount; // used for ERC-1155
  }

  // Both users are allowed to use NTFs and ETHs in the swap
  // Here we assume that user A is the one who create the swap
  struct Swap {
    // User A's swap information
    address payable aAddress;
    NFT[] aNFTs;
    uint256 aEth;

    // User B's swap information
    address payable bAddress;
    NFT[] bNFTs;
    uint256 bEth;
  }

  event FeeChange(uint256 fee);
  // SwapCreate will be emitted when user A create a swap
  event SwapCreate(
    address indexed a,
    address indexed b,
    uint256 indexed id,
    NFT[] aNFTs,
    uint256 aEth
  );
  // SwapReady will be emitted when user B finish selecting his/her NFTs and ETHs to swap
  event SwapReady(
    address indexed a,
    address indexed b,
    uint256 indexed id,
    NFT[] aNFTs,
    uint256 aEth,
    NFT[] bNFTs,
    uint256 bEth
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

  modifier onlyA(uint256 swapId) {
    require(_swaps[swapId].aAddress == msg.sender, "onlySwapCreatorCanCall");
    _;
  }

  modifier chargeFee() {
    require(msg.value >= _fee, "feeNotGiven");
    _;
  }

  constructor(uint128 fee, address owner) {
    _fee = fee;
    super.transferOwnership(owner);
  }

  // Change the contract service fee
  function changeFee(uint128 fee) external onlyOwner {
    _fee = fee;
    emit FeeChange(_fee);
  }

  // User A create a swap
  function createSwap(address bAddress, NFT[] memory aNFTs) external payable chargeFee {
    _swapIdx += 1;

    safeTransfer(msg.sender, address(this), aNFTs);

    Swap storage swap = _swaps[_swapIdx];

    swap.aAddress = payable(msg.sender);
    swap.aNFTs = aNFTs;

    if (msg.value > _fee) {
      swap.aEth = msg.value - _fee;
      _ethLocked += swap.aEth;
    }

    swap.bAddress = payable(bAddress);

    emit SwapCreate(msg.sender, swap.bAddress, _swapIdx, aNFTs, swap.aEth);
  }

  // User B init the swap
  function initSwap(uint256 id, NFT[] memory bNFTs) external payable chargeFee {
    require(_swaps[id].bAddress != msg.sender, "notCorrectUserB");
    require(_swaps[id].bNFTs.length == 0 && _swaps[id].bEth == 0, "swapAlreadyInit");

    safeTransfer(msg.sender, address(this), bNFTs);

    _swaps[id].bAddress = payable(msg.sender);
    _swaps[id].bNFTs = bNFTs;

    if (msg.value > _fee) {
      _swaps[id].bEth = msg.value - _fee;
      _ethLocked += _swaps[id].bEth;
    }

    emit SwapReady(
      _swaps[id].aAddress,
      _swaps[id].bAddress,
      id,
      _swaps[id].aNFTs,
      _swaps[id].aEth,
      _swaps[id].bNFTs,
      _swaps[id].bEth
    );
  }

  function safeTransfer(address from, address to, NFT[] memory nfts) internal {
    for (uint256 i = 0; i < nfts.length; i++) {
      // ERC-20 transfer
      if (nfts[i].amount == 0) {
        IERC721(nfts[i].contractAddr).safeTransferFrom(from, to, nfts[i].id, "");
      } else { // ERC-1155 transfer
        IERC1155(nfts[i].contractAddr).safeTransferFrom(from, to, nfts[i].id, nfts[i].amount, "");
      }
    }
  }

  function withdrawFee(address payable recipient) external onlyOwner {
    require(recipient != address(0), "canNotWithdrawToAddress0");

    recipient.transfer(address(this).balance - _ethLocked);
  }
}
