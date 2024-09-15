import { task } from "hardhat/config";
import type { TaskArguments } from "hardhat/types";

import { IMG_1 } from "./img_1";
import { IMG_2 } from "./img_2";
import { IMG_3 } from "./img_3";

task("task:deploy").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const signers = await ethers.getSigners();
  const deployer = signers[0];

  const yfgFactory = await ethers.getContractFactory("YieldForGood");
  const yfgContract = await yfgFactory.connect(deployer).deploy();
  await yfgContract.waitForDeployment();
  const yfgContractAddress = await yfgContract.getAddress();
  console.log("YFG deployed to: ", await yfgContract.getAddress());

  const svgImagesFactory = await ethers.getContractFactory("SVGImages");
  const svgImagesContract = await svgImagesFactory.connect(deployer).deploy();
  await svgImagesContract.waitForDeployment();
  const svgImagesContractAddress = await svgImagesContract.getAddress();
  console.log("SvgImages deployed to: ", await svgImagesContract.getAddress());

  const yfgSbFactory = await ethers.getContractFactory("YieldForGoodSoulBound");
  const yfgSbContract = await yfgSbFactory
    .connect(deployer)
    .deploy("Yield For Good Proof of Contribution", "YFG PoC", svgImagesContractAddress);
  await yfgSbContract.waitForDeployment();
  const yfgSbContractAddress = await yfgSbContract.getAddress();
  console.log("YFG SB deployed to: ", await yfgSbContract.getAddress());

  // ApeCoin
  const erc20FactoryApe = await ethers.getContractFactory("MockERC20");
  const erc20ContractApe = await erc20FactoryApe.connect(deployer).deploy("Ape Coin", "APE");
  await erc20ContractApe.waitForDeployment();
  const erc20ContractAddressApe = await erc20ContractApe.getAddress();
  console.log("ApeCoin ERC20 deployed to: ", await erc20ContractApe.getAddress());

  const stakingRewardsFactoryApe = await ethers.getContractFactory("MockStakingRewards");
  const stakingRewardsContractApe = await stakingRewardsFactoryApe
    .connect(deployer)
    .deploy(erc20ContractAddressApe, erc20ContractAddressApe, 31536000, 0);
  await stakingRewardsContractApe.waitForDeployment();
  const stakingRewardsContractAddressApe = await stakingRewardsContractApe.getAddress();
  console.log("Ape Coin StakingRewards deployed to: ", await stakingRewardsContractApe.getAddress());

  await erc20ContractApe.mint(stakingRewardsContractAddressApe, "1000000000000000000000000000");

  const vaultFactoryApe = await ethers.getContractFactory("MockVault");
  const vaultContractApe = await vaultFactoryApe
    .connect(deployer)
    .deploy(erc20ContractAddressApe, stakingRewardsContractAddressApe, "Staked Ape Coin", "sAPE");
  await vaultContractApe.waitForDeployment();
  const vaultContractAddressApe = await vaultContractApe.getAddress();
  console.log("ApeCoin Vault deployed to: ", await vaultContractApe.getAddress());

  // DAI
  const erc20FactoryDADI = await ethers.getContractFactory("MockERC20");
  const erc20ContractDAI = await erc20FactoryDADI.connect(deployer).deploy("Dai Stablecoin", "DAI");
  await erc20ContractDAI.waitForDeployment();
  const erc20ContractAddressDAI = await erc20ContractDAI.getAddress();
  console.log("DAI ERC20 deployed to: ", await erc20ContractDAI.getAddress());

  const stakingRewardsFactoryDAI = await ethers.getContractFactory("MockStakingRewards");
  const stakingRewardsContractDAI = await stakingRewardsFactoryDAI
    .connect(deployer)
    .deploy(erc20ContractAddressDAI, erc20ContractAddressDAI, 31536000, 0);
  await stakingRewardsContractDAI.waitForDeployment();
  const stakingRewardsContractAddressDAI = await stakingRewardsContractDAI.getAddress();
  console.log("DAI StakingRewards deployed to: ", await stakingRewardsContractDAI.getAddress());

  await erc20ContractDAI.mint(stakingRewardsContractAddressDAI, "1000000000000000000000000000");

  const vaultFactoryDAI = await ethers.getContractFactory("MockVault");
  const vaultContractDAI = await vaultFactoryDAI
    .connect(deployer)
    .deploy(erc20ContractAddressDAI, stakingRewardsContractAddressDAI, "Savings Dai", "sDAI");
  await vaultContractDAI.waitForDeployment();
  const vaultContractAddressDAI = await vaultContractDAI.getAddress();
  console.log("DAI Vault deployed to: ", await vaultContractDAI.getAddress());

  // USDC
  const erc20Factory = await ethers.getContractFactory("MockERC20");
  const erc20Contract = await erc20Factory.connect(deployer).deploy("USD Coin", "USDC");
  await erc20Contract.waitForDeployment();
  const erc20ContractAddress = await erc20Contract.getAddress();
  console.log("USDC ERC20 deployed to: ", await erc20Contract.getAddress());

  const stakingRewardsFactory = await ethers.getContractFactory("MockStakingRewards");
  const stakingRewardsContract = await stakingRewardsFactory
    .connect(deployer)
    .deploy(erc20ContractAddress, erc20ContractAddress, 31536000, 0);
  await stakingRewardsContract.waitForDeployment();
  const stakingRewardsContractAddress = await stakingRewardsContract.getAddress();
  console.log("USDC StakingRewards deployed to: ", await stakingRewardsContract.getAddress());

  await erc20Contract.mint(stakingRewardsContractAddress, "1000000000000000000000000000");

  const vaultFactory = await ethers.getContractFactory("MockVault");
  const vaultContract = await vaultFactory
    .connect(deployer)
    .deploy(erc20ContractAddress, stakingRewardsContractAddress, "Savings USD Coin", "sUSDC");
  await vaultContract.waitForDeployment();
  const vaultContractAddress = await vaultContract.getAddress();
  console.log("USDC Vault deployed to: ", await vaultContract.getAddress());

  await yfgContract.updateSupportedYieldSource(vaultContractAddressApe, true);
  await yfgContract.updateSupportedYieldSource(vaultContractAddressDAI, true);
  await yfgContract.updateSupportedYieldSource(vaultContractAddress, true);

  await yfgContract.createPool(
    vaultContractAddressApe,
    "CHILDREN FACING A WATER CRISIS NEED YOUR HELP",
    "UNICEF launched the Water Under Fire campaign to draw global attention to three fundamental areas where changes are urgently needed to secure access to safe and sustainable water and sanitation in fragile contexts.",
    "https://unicef.or.th/donate/uploads/a46VODlzGrEoRRhmjpe8qlfanSctMKsba4KrZBlh.png",
  );

  await yfgContract.createPool(
    vaultContractAddressDAI,
    "Protect the World's Forests",
    "For years, deforestation has been creeping into our home. Our fridge. Our lunch. Our coffee and the paper cups it comes in.",
    "https://wwfeu.awsassets.panda.org/img/original/wwf_t4f_email_signature_jaguar_1200x630__1_.png",
  );

  await yfgContract.createPool(
    vaultContractAddress,
    "Connect Capital to Communities that Need it the Most",
    "It is vital to connect with communities in need for capital to improve their life.",
    "https://images.prismic.io/impact-market/ed9a450e-df79-49ff-ae5e-1c35e2b361a2_seoimage.jpg?auto=compress,format",
  );

  await yfgContract.createPool(
    vaultContractAddress,
    "Connect Capital to Communities that Need it the Most",
    "If you ever visited Wikipedia, you might have seen a message asking you for a small donation. That is because Wikipedia and the 12 other free knowledge projects that are operated by the Wikimedia Foundation are made possible mostly by donations from individual donors like you. Watch to learn more.",
    "https://i.ytimg.com/vi/DkTj2NHKITE/maxresdefault.jpg",
  );

  await yfgContract.createPool(
    vaultContractAddress,
    "Creates new opportunities for girls and gender nonconforming youth of color",
    "Black girls and gender nonconforming youth of color can power the future. Their code gets us there. We support their creativity and boldness with skills, training, and resources that launch their leadership.",
    "https://i.ytimg.com/vi/rFKVTNoegAY/maxresdefault.jpg",
  );

  await svgImagesContract.addImage(IMG_1, 0);
  await svgImagesContract.addImage(IMG_2, 1);
  await svgImagesContract.addImage(IMG_3, 2);

  await yfgContract.setYFGSoulbound(yfgSbContractAddress);
  await yfgSbContract.setYFG(yfgContractAddress);

  await stakingRewardsContractApe.notifyRewardAmount("1000000000000000000000000000");
  await stakingRewardsContractDAI.notifyRewardAmount("1000000000000000000000000000");
  await stakingRewardsContract.notifyRewardAmount("1000000000000000000000000000");

  const pool = await yfgContract.pools(1);
  console.log("Pool: ", pool);
});
