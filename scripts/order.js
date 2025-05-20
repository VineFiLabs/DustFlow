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

  const GovernanceAddress = Deployed[chainId].Governance;
  const Governance = new ethers.Contract(
    GovernanceAddress,
    GovernanceABI.abi,
    owner
  );
  console.log("Governance Address:", GovernanceAddress);

  const getMarketConfig = await Governance.getMarketConfig(0);
  console.log("getMarketConfig:", getMarketConfig);

  const DustFlowFactoryAddress = Deployed[chainId].DustFlowFactory;
  const DustFlowFactory = new ethers.Contract(
    DustFlowFactoryAddress,
    DustFlowFactoryABI.abi,
    owner
  );
  console.log("DustFlowFactory Address:", DustFlowFactoryAddress);

  const marketId = await DustFlowFactory.marketId();
  console.log("lastest marketId:", marketId);

  const getMarketInfo1 = await DustFlowFactory.getMarketInfo(0n);
  console.log("getMarketInfo1:", getMarketInfo1);

  const Market = new ethers.Contract(
    getMarketInfo1[0],
    DustFlowCoreABI.abi,
    owner
  );

  const USDCAddress = Deployed[chainId].USDC;

  const USDC = new ethers.Contract(USDCAddress, ERC20ABI.abi, owner);
  const usdcDecimals = await USDC.decimals();
  console.log("USDC Decimals:", usdcDecimals);

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
    getMarketInfo1[0],
    ethers.parseEther("1000000000")
  );


  // const mintDust = await DustCore.mintDust(
  //   10000n * 10n ** 18n
  // );
  // const mintDustTx = await mintDust.wait();
  // console.log("mintDust tx:", mintDustTx.hash);

  const OrderType = {
    buy: 0,
    sell: 1,
  };

  const putTrade = await Market.putTrade(
    OrderType.sell,
    100n * 10n ** 6n,
    2n * 10n ** 5n,
  );
  const putTradeTx = await putTrade.wait();
  console.log("putTradeTx:", putTradeTx.hash);

  // const matchTrade = await Market.matchTrade(
  //   OrderType.buy,
  //   100n * 10n ** 6n,
  //   2n * 10n ** 5n,
  //   [0],
  // );
  // const matchTradeTx = await matchTrade.wait();
  // console.log("matchTradeTx:", matchTradeTx.hash);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
