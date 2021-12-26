const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTSwap", function () {
  it("Should init with give fee", async function () {
    const Swap = await ethers.getContractFactory("NFTSwap");
    const swap = await Swap.deploy(100);
    await swap.deployed();

    expect(await swap.getFee()).to.equal(100);
  });
});
