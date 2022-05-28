import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

import { deployUpgradableContract } from "../hardhat.util";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const accounts = await hre.getUnnamedAccounts();

  await deployUpgradableContract(
    hre.deployments,
    accounts[0],
    accounts[0],
    "ERC721LinearAutomaticDistributor",
    []
  );
};

export default func;
