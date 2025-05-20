const hre = require("hardhat");
const fs = require("fs");

const GovernanceABI = require("../artifacts/contracts/core/Governance.sol/Governance.json");
const TimeFlowFactoryABI = require("../artifacts/contracts/core/TimeFlowFactory.sol/TimeFlowFactory.json");
const TimeFlowCoreABI = require("../artifacts/contracts/core/TimeFlowCore.sol/TimeFlowCore.json");
const DustCoreABI = require("../artifacts/contracts/core/DustCore.sol/DustCore.json");
const DustABI = require("../artifacts/contracts/core/Dust.sol/Dust.json");
const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");

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

  // const governance = await ethers.getContractFactory("Governance");
  // const Governance = await governance.deploy(
  //   owner.address,
  //   owner.address,
  //   owner.address,
  //   owner.address
  // );
  // const GovernanceAddress = await Governance.target;
  const GovernanceAddress = "0xB3aDc46252C2abd33903854A6D5bD37500eAD989";
  const Governance = new ethers.Contract(
    GovernanceAddress,
    GovernanceABI.abi,
    owner
  );
  console.log("Governance Address:", GovernanceAddress);

  //   const initMarketConfig = await Governance.initMarketConfig(
  //     0,
  //     USDTAddress,
  //     ZERO_ADDRESS,
  //     ZERO_ADDRESS
  //   );
  //   const initMarketConfigTx = await initMarketConfig.wait();
  //   console.log("initMarketConfigTx:", initMarketConfigTx.hash);

  //   const setMarketConfig = await Governance.setMarketConfig(
  //     0,
  //     864000n,
  //     TFPTTAddress
  //   )
  //   const setMarketConfigTx = await setMarketConfig.wait();
  //   console.log("setMarketConfigTx:", setMarketConfigTx.hash);

  //   const getMarketConfig = await Governance.getMarketConfig(0);
  //   console.log("getMarketConfig:", getMarketConfig);

  //   const timeFlowFactory = await ethers.getContractFactory("TimeFlowFactory");
  //   const TimeFlowFactory = await timeFlowFactory.deploy(
  //     GovernanceAddress
  //   );
  //   const TimeFlowFactoryAddress = await TimeFlowFactory.target;
  const TimeFlowFactoryAddress = "0xBD4160794972C1e9b09a081bc8AFB2A51965F735";
  const TimeFlowFactory = new ethers.Contract(
    TimeFlowFactoryAddress,
    TimeFlowFactoryABI.abi,
    owner
  );
  console.log("TimeFlowFactory Address:", TimeFlowFactoryAddress);

  //   const timeFlowHelper = await ethers.getContractFactory("TimeFlowHelper");
  //   const TimeFlowHelper = await timeFlowHelper.deploy(
  //     GovernanceAddress,
  //     TimeFlowFactoryAddress
  //   );
  //   const TimeFlowHelperAddress = await TimeFlowHelper.target;
  const TimeFlowHelperAddress = "0x2d0DEEba4d7C14a88D48630c20E5fE9afe3B5BC3";
  console.log("TimeFlowHelper Address:", TimeFlowHelperAddress);

//   const dustCore = await ethers.getContractFactory("DustCore");
//   const DustCore = await dustCore.deploy(
//     owner.address,
//     owner.address
//   );
//   const DustCoreAddress = await DustCore.target;

  const DustCoreAddress = "0x07dEbc8B45D48eBe00DdCbA4d99647d741F0Bb5b";
  const DustCore = new ethers.Contract(DustCoreAddress, DustCoreABI.abi, owner);
  console.log("DustCore Address:", DustCoreAddress);

  // const dust = await ethers.getContractFactory("Dust");
  // const Dust = await dust.deploy(
  //   DustCoreAddress,
  //   {gasLimit: 1000000}
  // );
  // const DustAddress = await Dust.target;

  const DustAddress = "0x6Fee1E15E0540053D536bBdbEED24cD1B6f4834C";
  const Dust = new ethers.Contract(DustAddress, DustABI.abi, owner);
  console.log("Dust Address:", DustAddress);

  //   const changeDust = await DustCore.changeDust(DustAddress);
  //   const changeDustTx = await changeDust.wait();
  //   console.log("changeDust:", changeDustTx.hash);

//   const changeCaller = await Dust.changeCaller(DustAddress, {gasLimit: 100000});
//   const changeCallerTx = await changeCaller.wait();
//   console.log("changeCaller:", changeCallerTx.hash);

  const thisDust = await DustCore.dust();
  console.log("thisDust:", thisDust);

  if (thisDust === ZERO_ADDRESS) {
    const initialize = await DustCore.initialize(
      DustAddress,
      [95],
      [10],
      [USDTAddress]
    );
    const initializeTx = await initialize.wait();
    console.log("initialize:", initializeTx.hash);
  }

  const getExpectedAmount = await DustCore.getExpectedAmount(
    USDTAddress,
    1000n * 10n ** 18n,
    10n ** 6n
  );
  console.log("getExpectedAmount:", getExpectedAmount);

  async function Approve(token, spender, amount) {
    try {
      const tokenContract = new ethers.Contract(token, ERC20ABI.abi, owner);
      const allowance = await tokenContract.allowance(owner.address, spender);
      if (allowance < ethers.parseEther("10000")) {
        const approve = await tokenContract.approve(spender, amount, {gasLimit: 300000});
        const approveTx = await approve.wait();
        console.log("approveTx:", approveTx.hash);
      } else {
        console.log("Not approve");
      }
    } catch (e) {
      console.log("e:", e);
    }
  }
  await Approve(USDTAddress, DustCore, ethers.parseEther("1000000000"));

  const mintDust = await DustCore.mintDust(
    USDTAddress,
    100n * 10n ** 18n,
    10n ** 6n,
    { gasLimit: 1250000 }
  );
  const mintDustTx = await mintDust.wait();
  console.log("mintDust:", mintDustTx.hash);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
