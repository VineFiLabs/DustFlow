const hre = require("hardhat");
const fs = require("fs");

const GovernanceABI = require("../artifacts/contracts/core/Governance.sol/Governance.json");
const TimeFlowFactoryABI = require("../artifacts/contracts/core/TimeFlowFactory.sol/TimeFlowFactory.json");
const TimeFlowCoreABI = require("../artifacts/contracts/core/TimeFlowCore.sol/TimeFlowCore.json");
const DustCoreABI = require("../artifacts/contracts/core/DustCore.sol/DustCore.json");
const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const TimeFlowHelperABI = require("../artifacts/contracts/helper/TimeFlowHelper.sol/TimeFlowHelper.json");

async function main() {
  const [owner] = await hre.ethers.getSigners();
  console.log("owner:", owner.address);

  const provider = ethers.provider;
  const network = await provider.getNetwork();
  const chainId = network.chainId;
  console.log("Chain ID:", chainId);

  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
  let config = {};

  async function sendETH(toAddress, amountInEther) {
    const amountInWei = ethers.parseEther(amountInEther);
    const tx = {
      to: toAddress,
      value: amountInWei,
    };
    const transactionResponse = await owner.sendTransaction(tx);
    await transactionResponse.wait();
    console.log("Transfer eth success");
  }

  let allAddresses = {};

  const USDTAddress = "0xB3aDc46252C2abd33903854A6D5bD37500eAD989";
  console.log("USDT Address:", USDTAddress);

  const TFPTTAddress = "0xfbF60F3cc210f7931c3c15920CC71A03C0B4dAc3";
  console.log("TFPTT Address:", TFPTTAddress);

  const DustCoreAddress = "0x9096DC35B9A851134cb2f82eD6c7cFEE08D1f024";
  const DustCore = new ethers.Contract(DustCoreAddress, DustCoreABI.abi, owner);
  console.log("DustCore Address:", DustCoreAddress);

  const GovernanceAddress = "0x55114d8eF1C57dc96481008D70883Ce2A8153C03";
  const Governance = new ethers.Contract(
    GovernanceAddress,
    GovernanceABI.abi,
    owner
  );
  console.log("Governance Address:", GovernanceAddress);

  const getMarketConfig = await Governance.getMarketConfig(0);
  console.log("getMarketConfig:", getMarketConfig);

  const TimeFlowFactoryAddress = "0xc8CDf868157e0a14B1e65B917cf4686E77556A08";
  const TimeFlowFactory = new ethers.Contract(TimeFlowFactoryAddress, TimeFlowFactoryABI.abi, owner);
  console.log("TimeFlowFactory Address:", TimeFlowFactoryAddress);

  const TimeFlowHelperAddress = "0x7Bc0B773e4E3c3f3d5fA39897dbFeb4c27D4d6b7";
  const TimeFlowHelper = new ethers.Contract(
    TimeFlowHelperAddress,
    TimeFlowHelperABI.abi,
    owner
  );
  console.log("TimeFlowHelper Address:", TimeFlowHelperAddress);

  // const getOrderInfo = await TimeFlowHelper.getOrderInfo(
  //   0,
  //   30
  // );
  // console.log("getOrderInfo:", getOrderInfo);

  // const getOrderState = await TimeFlowHelper.getOrderState(
  //   0,
  //   30
  // );
  // console.log("getOrderState:", getOrderState);

  const user = "0x71e87C493a0c70221B55bc35C4fe91e52bCb988a";
  const  getUserFlowId = await DustCore.getUserFlowId(user, 1, 7);
  console.log("getUserFlowId:", getUserFlowId);




}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
