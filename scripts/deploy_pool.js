const hre = require("hardhat");
const fs = require("fs");
const DustPoolABI = require("../artifacts/contracts/core/DustPool.sol/DustPool.json");
const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const Set = require("../deployedAddress.json");

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

  const data = Set[chainId];

  let allAddresses = {};
  const dust = data.DustCore;
  const usdc = data.USDC;
  const dustPool = await ethers.getContractFactory("DustPool");
  const DustPool = await dustPool.deploy(
    owner.address, 
    owner.address, 
    dust,
    usdc
  );
  const DustPoolAddress = await DustPool.target;
  //   const DustPoolAddress = "";
  //   const DustPool = new ethers.Contract(DustPoolAddress, DustPoolABI.abi, owner);
  console.log("DustPool Address:", DustPoolAddress);

  const DUST = new ethers.Contract(dust, ERC20ABI.abi, owner);

  // const transfer = await DUST.transfer(DustPoolAddress, ethers.parseEther("100"));
  // const transferTx = await transfer.wait();
  // console.log("Transfer tx:", transferTx.hash);

  //

  config.USDC = data.USDC;
  config.DTT = data.DTT;
  config.DustCore = data.DustCore;
  config.DustPool = DustPoolAddress;
  (config.Governance = data.Governance),
    (config.DustFlowFactory = data.DustFlowFactory),
    (config.DustFlowHelper = data.DustFlowHelper);
  (config.market0 = data.market0),
    (config.market1 = data.market1),
    (config.updateTime = new Date().toISOString());

  const filePath = "./deployedAddress.json";
  if (fs.existsSync(filePath)) {
    allAddresses = JSON.parse(fs.readFileSync(filePath, "utf8"));
  }
  allAddresses[chainId] = config;

  fs.writeFileSync(filePath, JSON.stringify(allAddresses, null, 2), "utf8");
  console.log("deployedAddress.json update:", allAddresses);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
