/* eslint-disable camelcase */
import { expect } from "chai";
import { ethers, getUnnamedAccounts, getChainId } from "hardhat";
import { ERC721SimpleOneOfOneCollection__factory } from "../../../typechain/factories/ERC721SimpleOneOfOneCollection__factory";
import { UnorderedForwarder__factory } from "../../../typechain/factories/UnorderedForwarder__factory";
import {
  signUnorderedMetaTransaction,
  UnorderedMetaTransaction,
} from "../../utils/meta-transactions";

describe("ERC721SimpleOneOfOneCollection", function () {
  it("should return collection info", async function () {
    const ERC721SimpleOneOfOneCollection =
      await ethers.getContractFactory<ERC721SimpleOneOfOneCollection__factory>(
        "ERC721SimpleOneOfOneCollection"
      );
    const collection = await ERC721SimpleOneOfOneCollection.deploy({
      name: "Flair Angels",
      symbol: "ANGEL",
      contractURI: "ipfs://yyyyy",
      maxSupply: 8000,
      trustedForwarder: "0x0000000000000000000000000000000000000000",
    });

    await collection.deployed();
    await collection.getInfo();
  });

  it("should mint 1 one-of-one token", async function () {
    const ERC721SimpleOneOfOneCollection =
      await ethers.getContractFactory<ERC721SimpleOneOfOneCollection__factory>(
        "ERC721SimpleOneOfOneCollection"
      );
    const collection = await ERC721SimpleOneOfOneCollection.deploy({
      name: "Flair Angels",
      symbol: "ANGEL",
      contractURI: "ipfs://yyyyy",
      maxSupply: 8000,
      trustedForwarder: "0x0000000000000000000000000000000000000000",
    });

    await collection.deployed();

    const [userA] = await getUnnamedAccounts();

    await collection.mintWithTokenURIsByOwner(userA, 1, ["ipfs://zzzzz"]);

    expect(await collection.balanceOf(userA)).to.equal(1);
    expect(await collection.tokenURI(1)).to.equal("ipfs://zzzzz");
  });

  it("should mint 1 one-of-one token via meta transactions", async function () {
    const UnorderedForwarder =
      await ethers.getContractFactory<UnorderedForwarder__factory>(
        "UnorderedForwarder"
      );
    const forwarder = await (await UnorderedForwarder.deploy({})).deployed();

    const ERC721SimpleOneOfOneCollection =
      await ethers.getContractFactory<ERC721SimpleOneOfOneCollection__factory>(
        "ERC721SimpleOneOfOneCollection"
      );
    const collection = await ERC721SimpleOneOfOneCollection.deploy({
      name: "Flair Angels",
      symbol: "ANGEL",
      contractURI: "ipfs://yyyyy",
      maxSupply: 8000,
      trustedForwarder: forwarder.address,
    });

    await collection.deployed();

    const chainId = await getChainId();
    const [deployer, , userB] = await getUnnamedAccounts();

    const deployerSigner = await ethers.getSigner(deployer);

    const data = collection.interface.encodeFunctionData(
      "mintWithTokenURIsByOwner",
      [userB, 2, ["ipfs://zzzzz", "ipfs://wwwwww"]]
    );

    const metaTransaction: UnorderedMetaTransaction = {
      from: deployer,
      to: collection.address,
      value: 0,
      minGasPrice: 0,
      maxGasPrice: 1000000000,
      expiresAt: Math.floor(Date.now() / 1000 + 1000),
      nonce: Math.floor(Math.random() * 1000000000),
      data,
    };

    const signature = await signUnorderedMetaTransaction(
      deployerSigner,
      Number(chainId),
      metaTransaction,
      forwarder.address
    );

    await forwarder.batchExecute([metaTransaction], [signature]);

    expect(await collection.balanceOf(userB)).to.equal(2);
    expect(await collection.tokenURI(1)).to.equal("ipfs://zzzzz");
    expect(await collection.tokenURI(2)).to.equal("ipfs://wwwwww");
  });

  it("should failing minting 1 one-of-one token when not admin via meta transactions", async function () {
    const UnorderedForwarder =
      await ethers.getContractFactory<UnorderedForwarder__factory>(
        "UnorderedForwarder"
      );
    const forwarder = await (await UnorderedForwarder.deploy({})).deployed();

    const ERC721SimpleOneOfOneCollection =
      await ethers.getContractFactory<ERC721SimpleOneOfOneCollection__factory>(
        "ERC721SimpleOneOfOneCollection"
      );
    const collection = await ERC721SimpleOneOfOneCollection.deploy({
      name: "Flair Angels",
      symbol: "ANGEL",
      contractURI: "ipfs://yyyyy",
      maxSupply: 8000,
      trustedForwarder: forwarder.address,
    });

    await collection.deployed();

    const chainId = await getChainId();
    const [, userA, userB] = await getUnnamedAccounts();

    const signerA = await ethers.getSigner(userA);

    const data = collection.interface.encodeFunctionData(
      "mintWithTokenURIsByOwner",
      [userB, 2, ["ipfs://zzzzz", "ipfs://wwwwww"]]
    );

    const metaTransaction: UnorderedMetaTransaction = {
      from: userA,
      to: collection.address,
      value: 0,
      minGasPrice: 0,
      maxGasPrice: 1000000000,
      expiresAt: Math.floor(Date.now() / 1000 + 1000),
      nonce: Math.floor(Math.random() * 1000000000),
      data,
    };

    const signature = await signUnorderedMetaTransaction(
      signerA,
      Number(chainId),
      metaTransaction,
      forwarder.address
    );

    await expect(
      forwarder.batchExecute([metaTransaction], [signature])
    ).to.be.revertedWith("FWD_CALL_FAILED");

    expect(await collection.balanceOf(userA)).to.equal(0);
  });

  // it("should failing minting 1 one-of-one token when not admin via meta transactions", async function () {
  //   const ERC721SimpleOneOfOneCollection =
  //     await ethers.getContractFactory<ERC721SimpleOneOfOneCollection__factory>(
  //       "ERC721SimpleOneOfOneCollection"
  //     );
  //   const collection = await ERC721SimpleOneOfOneCollection.deploy({
  //     name: "Flair Angels",
  //     symbol: "ANGEL",
  //     contractURI: "ipfs://yyyyy",
  //     maxSupply: 8000,
  //     trustedForwarder: "0x0000000000000000000000000000000000000000",
  //   });

  //   await collection.deployed();

  //   const chainId = await getChainId();
  //   const [, userA, userB] = await getUnnamedAccounts();

  //   const signerA = await ethers.getSigner(userA);

  //   const callData = collection.interface.encodeFunctionData(
  //     "mintWithTokenURIsByOwner",
  //     [userB, 2, ["ipfs://zzzzz", "ipfs://wwwwww"]]
  //   );

  //   const metaTransaction = {
  //     signer: userA,
  //     callData,
  //     expiresAt: Math.floor(Date.now() / 1000 + 1000),
  //     minGasPrice: 0,
  //     maxGasPrice: 1000000000,
  //     salt: Math.floor(Math.random() * 1000000000),
  //     value: 0,
  //   };

  //   const signature = await signUnorderedMetaTransaction(
  //     signerA,
  //     Number(chainId),
  //     metaTransaction,
  //     collection.address
  //   );

  //   await expect(
  //     collection.batchExecuteMetaTransactions([metaTransaction], [signature])
  //   ).to.be.revertedWith("MTX_CALL_FAILED");
  // });

  // it("should failing minting 1 one-of-one token when impersonating admin via meta transactions", async function () {
  //   const ERC721SimpleOneOfOneCollection =
  //     await ethers.getContractFactory<ERC721SimpleOneOfOneCollection__factory>(
  //       "ERC721SimpleOneOfOneCollection"
  //     );
  //   const collection = await ERC721SimpleOneOfOneCollection.deploy({
  //     name: "Flair Angels",
  //     symbol: "ANGEL",
  //     contractURI: "ipfs://yyyyy",
  //     maxSupply: 8000,
  //   });

  //   await collection.deployed();

  //   const chainId = await getChainId();
  //   const [deployer, userA, userB] = await getUnnamedAccounts();

  //   const signerA = await ethers.getSigner(userA);

  //   const callData = collection.interface.encodeFunctionData(
  //     "mintWithTokenURIsByOwner",
  //     [userB, 2, ["ipfs://zzzzz", "ipfs://wwwwww"]]
  //   );

  //   const metaTransaction = {
  //     signer: deployer,
  //     callData,
  //     expiresAt: Math.floor(Date.now() / 1000 + 1000),
  //     minGasPrice: 0,
  //     maxGasPrice: 1000000000,
  //     salt: Math.floor(Math.random() * 1000000000),
  //     value: 0,
  //   };

  //   const signature = await signUnorderedMetaTransaction(
  //     signerA,
  //     Number(chainId),
  //     metaTransaction,
  //     collection.address
  //   );

  //   await expect(
  //     collection.batchExecuteMetaTransactions([metaTransaction], [signature])
  //   ).to.be.revertedWith("MTX_INVALID_SIGNATURE");
  // });
});
