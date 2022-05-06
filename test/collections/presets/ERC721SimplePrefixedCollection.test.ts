import { ethers } from "hardhat";
import { ERC721SimplePrefixedCollection } from "../../../typechain";

describe("ERC721SimplePrefixedCollection", function () {
  let collection: ERC721SimplePrefixedCollection;

  beforeEach(async () => {
    const ERC721SimplePrefixedCollectionContract = await ethers.getContractFactory(
      "ERC721SimplePrefixedCollection"
    );

    collection = (await ERC721SimplePrefixedCollectionContract.deploy(
      "Flair Angels",
      "ANGEL",
      "ipfs://xxxxx",
      "ipfs://yyyyy",
      10000
    )) as ERC721SimplePrefixedCollection;

    await collection.deployed();
  });

  it("should return collection info", async function () {
    await collection.getInfo();
  });
});
