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

  // const testToken = await ethers.getContractFactory("TestToken");
  // const USDT = await testToken.deploy(
  //   "TimeFlow Test USDT",
  //   "USDT"
  // );
  // const USDTAddress = await USDT.target;
  const USDTAddress = "0xFA8B026CaA2d1d73CE8A9f19613364FCa9440411";
  console.log("USDT Address:", USDTAddress);

  // const TFPTT = await testToken.deploy(
  //   "TimeFlow Test Pharos",
  //   "TF-PTT"
  // );
  // const TFPTTAddress = await TFPTT.target;
  const TFPTTAddress = "0xa5281122370d997c005B2313373Fa3CAf6A48Ae0";
  console.log("TFPTT Address:", TFPTTAddress);

  // const dustCore = await ethers.getContractFactory("DustCore");
  // const DustCore = await dustCore.deploy(
  //   owner.address,
  //   owner.address,
  //   {gasLimit: 4500000}
  // );
  // const DustCoreAddress = await DustCore.target;
  const DustCoreAddress = "0x9096DC35B9A851134cb2f82eD6c7cFEE08D1f024";
  const DustCore = new ethers.Contract(DustCoreAddress, DustCoreABI.abi, owner);
  console.log("DustCore Address:", DustCoreAddress);

  const TimeFlowFactoryAddress = "0xc8CDf868157e0a14B1e65B917cf4686E77556A08";
  const TimeFlowFactory = new ethers.Contract(
    TimeFlowFactoryAddress,
    TimeFlowFactoryABI.abi,
    owner
  );
  console.log("TimeFlowFactory Address:", TimeFlowFactoryAddress);

  const getMarketInfo1 = await TimeFlowFactory.getMarketInfo(0n);
  console.log("getMarketInfo1:", getMarketInfo1);

  const getMarketInfo2 = await TimeFlowFactory.getMarketInfo(1n);
  console.log("getMarketInfo2:", getMarketInfo2);

  const marketId = await TimeFlowFactory.marketId();
  console.log("lastest marketId:", marketId);

  const Market = new ethers.Contract(
    getMarketInfo1[0],
    TimeFlowCoreABI.abi,
    owner
  );

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
    DustCoreAddress,
    getMarketInfo1[0],
    ethers.parseEther("1000000000")
  );

  await Approve(USDTAddress, DustCoreAddress, ethers.parseEther("1000000000"));

  const OrderType = {
    buy: 0,
    sell: 1,
  };

  const withdraw = await Market.withdraw(OrderType.buy, [8], {gasLimit: 500000});
  const withdrawTx = await withdraw.wait();
  console.log("withdrawtx:", withdrawTx.hash);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
