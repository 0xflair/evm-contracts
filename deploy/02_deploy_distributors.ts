import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction, DeployResult } from "hardhat-deploy/types";

import { deployUpgradableContract } from "../hardhat.util";

export const delayMs = (ms: number) =>
  new Promise((resolve) => setTimeout(resolve, ms));

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const accounts = await hre.getUnnamedAccounts();

  const contract = (await deployUpgradableContract(
    hre.deployments,
    accounts[0],
    accounts[0],
    "ERC721LinearAutomaticDistributor",
    []
  )) as DeployResult;

  if (hre.network.name === "hardhat") {
    return;
  }

  await delayMs(2000);

  await hre.run("verify:verify", {
    address: contract.address,
    constructorArguments: [],
  });
};

export default func;
