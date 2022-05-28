import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deployments } from "hardhat";
import { ERC721LinearAutomaticDistributor } from "../typechain/ERC721LinearAutomaticDistributor";
import { TestERC20 } from "../typechain/TestERC20";
import { TestERC721 } from "../typechain/TestERC721";

const { deployPermanentContract } = require("../hardhat.util");

type ContractDictionary = {
  [contractName: string]: {
    signer: SignerWithAddress;
    ERC721LinearAutomaticDistributor: ERC721LinearAutomaticDistributor;
    TestERC721: TestERC721;
    TestERC20: TestERC20;
  };
};

export const setupTest = deployments.createFixture(
  async ({ deployments, getUnnamedAccounts, ethers }, options) => {
    const accounts = await getUnnamedAccounts();

    await deployments.fixture();

    await deployPermanentContract(
      deployments,
      accounts[0],
      accounts[0],
      "TestERC721",
      []
    );

    await deployPermanentContract(
      deployments,
      accounts[0],
      accounts[0],
      "TestERC20",
      []
    );

    return {
      deployer: {
        signer: await ethers.getSigner(accounts[0]),
        ERC721LinearAutomaticDistributor: await ethers.getContract(
          "ERC721LinearAutomaticDistributor",
          accounts[0]
        ),
        TestERC721: await ethers.getContract("TestERC721", accounts[0]),
        TestERC20: await ethers.getContract("TestERC20", accounts[0]),
      },
      userA: {
        signer: await ethers.getSigner(accounts[1]),
        ERC721LinearAutomaticDistributor: await ethers.getContract(
          "ERC721LinearAutomaticDistributor",
          accounts[1]
        ),
        TestERC721: await ethers.getContract("TestERC721", accounts[1]),
        TestERC20: await ethers.getContract("TestERC20", accounts[1]),
      },
      userB: {
        signer: await ethers.getSigner(accounts[2]),
        ERC721LinearAutomaticDistributor: await ethers.getContract(
          "ERC721LinearAutomaticDistributor",
          accounts[2]
        ),
        TestERC721: await ethers.getContract("TestERC721", accounts[2]),
        TestERC20: await ethers.getContract("TestERC20", accounts[2]),
      },
      userC: {
        signer: await ethers.getSigner(accounts[3]),
        ERC721LinearAutomaticDistributor: await ethers.getContract(
          "ERC721LinearAutomaticDistributor",
          accounts[3]
        ),
        TestERC721: await ethers.getContract("TestERC721", accounts[3]),
        TestERC20: await ethers.getContract("TestERC20", accounts[3]),
      },
    } as ContractDictionary;
  }
);
