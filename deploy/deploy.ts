import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  console.log(deployer);

  const yfgContract = await deploy("YieldForGood", {
    from: deployer,
    args: [],
    log: true,
  });

  console.log(`YFG contract: `, yfgContract.address);
};
export default func;
func.id = "deploy_yfg"; // id required to prevent reexecution
func.tags = ["YieldForGood"];
