const hre = require("hardhat");
const fs = require("fs");

const GovernanceABI = require("../artifacts/contracts/core/Governance.sol/Governance.json");
const DustFlowFactoryABI = require("../artifacts/contracts/core/DustFlowFactory.sol/DustFlowFactory.json");
const DustFlowCoreABI = require("../artifacts/contracts/core/DustFlowCore.sol/DustFlowCore.json");
const DustCoreABI = require("../artifacts/contracts/core/DustCore.sol/DustCore.json");
const DustAaveCoreABI = require("../artifacts/contracts/core/DustAaveCore.sol/DustAaveCore.json");
const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const DustFlowHelperABI = require("../artifacts/contracts/helper/DustFlowHelper.sol/DustFlowHelper.json");
const Deployed = require("../deployedAddress.json");

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
  const USDCAddress = Deployed[chainId].USDC;
  console.log("USDC:", USDCAddress);
  const DustCoreAddress =  Deployed[chainId].DustCore;
  console.log("DustCore:", DustCoreAddress);
  const DustCore = new ethers.Contract(DustCoreAddress, DustCoreABI.abi, owner);
  console.log("DustCore Address:", DustCoreAddress);

  const initializeState = await DustCore.initializeState();
  console.log("initializeState:", initializeState);
  if (initializeState === "0x00") {
    const initialize = await DustCore.initialize(USDCAddress);
    const initializeTx = await initialize.wait();
    console.log("initialize:", initializeTx.hash);
  }

  async function Approve(token, spender, amount) {
    try {
      const tokenContract = new ethers.Contract(token, ERC20ABI.abi, owner);
      const allowance = await tokenContract.allowance(owner.address, spender);
      if (allowance < ethers.parseEther("10000")) {
        const approve = await tokenContract.approve(spender, amount);
        const approveTx = await approve.wait();
        console.log("approveTx:", approveTx.hash);
      } else {
        console.log("Not approve");
      }
    } catch (e) {
      console.log("e:", e);
    }
  }
  await Approve(
    USDCAddress,
    DustCoreAddress,
    ethers.parseEther("1000000000")
  );

  const collateral = await DustCore.collateral();
  console.log("collateral:", collateral);

  const mintDust = await DustCore.mintDust(
    1000000,
    {gasLimit: 500000}
  );
  const mintDustTx = await mintDust.wait();
  console.log("mintDust:", mintDustTx.hash);


}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
