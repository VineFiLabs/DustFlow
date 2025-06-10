const hre = require("hardhat");
const fs = require("fs");

const GovernanceABI = require("../artifacts/contracts/core/Governance.sol/Governance.json");
const DustFlowFactoryABI = require("../artifacts/contracts/core/DustFlowFactory.sol/DustFlowFactory.json");
const DustFlowCoreABI = require("../artifacts/contracts/core/DustFlowCore.sol/DustFlowCore.json");
const DustCoreABI = require("../artifacts/contracts/core/DustCore.sol/DustCore.json");
const DustAaveCoreABI = require("../artifacts/contracts/core/DustAaveCore.sol/DustAaveCore.json");
const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const DustFlowHelperABI = require("../artifacts/contracts/helper/DustFlowHelper.sol/DustFlowHelper.json");
const Set = require("../set.json");

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
  let chainConfig;
  let USDCAddress;
  let DustCore;
  let DustCoreAddress;
  let ThisDustCoreABI;
  if (chainId === 1n || chainId === 11155111n) {
    chainConfig = Set["Ethereum_Sepolia"];
    USDCAddress = chainConfig.USDC;
  } else if (chainId === 42161n || chainId === 421614n) {
    chainConfig = Set["Arbitrum_Sepolia"];
    USDCAddress = chainConfig.USDC;
  } else if (chainId === 43114n || chainId === 43113n) {
    chainConfig = Set["Avalanche_Fuji"];
    USDCAddress = chainConfig.USDC;
  } else if (chainId === 8453n || chainId === 84532n) {
    chainConfig = Set["Base_Sepolia"];
    USDCAddress = chainConfig.USDC;
  } else if (chainId === 10n || chainId === 11155420n) {
    chainConfig = Set["Op_Sepolia"];
    USDCAddress = chainConfig.USDC;
  } else {
    // const usdc = await ethers.getContractFactory("TestToken");
    // const USDC = await usdc.deploy("DustFlow Test USDC", "USDC", 6);
    // USDCAddress = await USDC.target;
    USDCAddress = "0xDF914A54fD5081FF5001b225191Cf41C8A40abF4";
  }
  console.log("USDC Address:", USDCAddress);

  // const testToken = await ethers.getContractFactory("TestToken");
  // const DTT = await testToken.deploy("DustFlow Test Token", "DTT", 18);
  // const DTTAddress = await DTT.target;
  const DTTAddress = "0x183598b50174566b46bd419b392c1B8FC9087cB3";
  console.log("DTT Address:", DTTAddress);

  // const WETH = await testToken.deploy("Test WETH Token", "WETH", 18);
  // const WETHAddress = await WETH.target;
  const WETHAddress = "0x0B89A5452bee7e40331af133379c24735E2001Ef";
  console.log("WETH Address:", WETHAddress);

  if (chainId === 421614n || chainId === 43113n || chainId === 84532n || chainId === 11155420n) {
    const dustCore = await ethers.getContractFactory("DustAaveCore");
    DustCore = await dustCore.deploy(
      chainConfig.AaveV3Pool,
      chainConfig.AUSDC,
      owner.address,
      owner.address,
      owner.address,
      USDCAddress,
      5000
    );
    DustCoreAddress = await DustCore.target;
    ThisDustCoreABI = DustAaveCoreABI.abi;
  }else {
    // const dustCore = await ethers.getContractFactory("DustCore");
    // DustCore = await dustCore.deploy(
    //   owner.address,
    //   owner.address,
    //   owner.address,
    //   USDCAddress,
    //   5000
    // );
    // DustCoreAddress = await DustCore.target;
    ThisDustCoreABI = DustCoreABI.abi;
  }
  DustCoreAddress = "0xFA8B026CaA2d1d73CE8A9f19613364FCa9440411";
  DustCore = new ethers.Contract(DustCoreAddress, ThisDustCoreABI, owner);
  console.log("DustCore Address:", DustCoreAddress);

  // const dustPool = await ethers.getContractFactory("DustPool");
  // const DustPool = await dustPool.deploy(
  //   owner.address,
  //   owner.address,
  //   DustCoreAddress,
  //   USDCAddress
  // );
  // const DustPoolAddress = await DustPool.target;
  const DustPoolAddress = "0xa5281122370d997c005B2313373Fa3CAf6A48Ae0";
  console.log("DustPoolAddress:", DustPoolAddress);

  // const governance = await ethers.getContractFactory("Governance");
  // const Governance = await governance.deploy(
  //   owner.address,
  //   owner.address,
  //   USDCAddress,
  //   DustPoolAddress,
  //   owner.address
  // );
  // const GovernanceAddress = await Governance.target;
  const GovernanceAddress = "0x9e001cd69F1565289a36BB6E74cb61Ba7E89940e";
  const Governance = new ethers.Contract(
    GovernanceAddress,
    GovernanceABI.abi,
    owner
  );
  console.log("Governance Address:", GovernanceAddress);

  // const setMarketConfig = await Governance.setMarketConfig(
  //   0,
  //   864000n,
  //   DTTAddress,
  //   {gasLimit: 100000}
  // );
  // const setMarketConfigTx = await setMarketConfig.wait();
  // console.log("setMarketConfigTx:", setMarketConfigTx.hash);

  const getMarketConfig = await Governance.getMarketConfig(0);
  console.log("getMarketConfig:", getMarketConfig);

  // const dustFlowFactory = await ethers.getContractFactory("DustFlowFactory");
  // const DustFlowFactory = await dustFlowFactory.deploy(GovernanceAddress);
  // const DustFlowFactoryAddress = await DustFlowFactory.target;
  const DustFlowFactoryAddress = "0x97eC4D44298b4E2C39dD4c0a841b12eC16616356";
  const DustFlowFactory = new ethers.Contract(
    DustFlowFactoryAddress,
    DustFlowFactoryABI.abi,
    owner
  );
  console.log("DustFlowFactory Address:", DustFlowFactoryAddress);

  // const dustFlowHelper = await ethers.getContractFactory("DustFlowHelper");
  // const DustFlowHelper = await dustFlowHelper.deploy(
  //   GovernanceAddress,
  //   DustFlowFactoryAddress
  // );
  // const DustFlowHelperAddress = await DustFlowHelper.target;
  const DustFlowHelperAddress = "0x08A10f9C46F464705E3791F55B8CA8f7d4A4E6bc";
  const DustFlowHelper = new ethers.Contract(
    DustFlowHelperAddress,
    DustFlowHelperABI.abi,
    owner
  );
  console.log("DustFlowHelper Address:", DustFlowHelperAddress);

  // const changeDustFlowFactory = await Governance.changeDustFlowFactory(
  //   DustFlowFactoryAddress
  // );
  // const changeDustFlowFactoryTx = await changeDustFlowFactory.wait();
  // console.log("changeDustFlowFactory:", changeDustFlowFactoryTx.hash);

  // const changeConfig = await DustFlowHelper.changeConfig(
  //   GovernanceAddress,
  //   DustFlowFactoryAddress,
  //   { gasLimit: 300000 }
  // );
  // const changeConfigTx = await changeConfig.wait();
  // console.log("changeConfig:", changeConfigTx.hash);

  const getMarketConfig0 = await Governance.getMarketConfig(0);
  console.log("getMarketConfig:", getMarketConfig0);

  // const changeCollateral = await Governance.changeCollateral(
  //   0,
  //   DustCoreAddress,
  //   {
  //     gasLimit: 100000,
  //   }
  // );
  // const changeCollateralTx = await changeCollateral.wait();
  // console.log("changeCollateral:", changeCollateralTx.hash);

  // const createMarket1 = await DustFlowFactory.createMarket({
  //   gasLimit: 5200000
  // });
  // const createMarket1Tx = await createMarket1.wait();
  // console.log("createMarket1 tx:", createMarket1Tx.hash);

  const getMarketInfo1 = await DustFlowFactory.getMarketInfo(0n);
  console.log("getMarketInfo1:", getMarketInfo1);

  const createMarket2 = await DustFlowFactory.createMarket(
    {gasLimit: 5200000}
  );
  const createMarket2Tx = await createMarket2.wait();
  console.log("createMarket2 tx:", createMarket2Tx.hash);

  const getMarketInfo2 = await DustFlowFactory.getMarketInfo(1n);
  console.log("getMarketInfo2:", getMarketInfo2);

  const marketId = await DustFlowFactory.marketId();
  console.log("lastest marketId:", marketId);

  const Market = new ethers.Contract(
    getMarketInfo1[0],
    DustFlowCoreABI.abi,
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

  await Approve(USDCAddress, DustCoreAddress, ethers.parseEther("1000000000"));

  const setMarketConfig2 = await Governance.setMarketConfig(
    1,
    864000n,
    WETHAddress
  );
  const setMarketConfig2Tx = await setMarketConfig2.wait();
  console.log("setMarketConfig2Tx:", setMarketConfig2Tx.hash);

  // const mintDust = await DustCore.mintDust(
  //   10000n * 10n ** 18n
  // );
  // const mintDustTx = await mintDust.wait();
  // console.log("mintDust tx:", mintDustTx.hash);

  const OrderType = {
    buy: 0,
    sell: 1,
  };

  // const putTrade = await Market.putTrade(
  //   OrderType.sell,
  //   50n * 10n ** 18n,
  //   2n * 10n ** 5n,
  //   { gasLimit: 500000 }
  // );
  // const putTradeTx = await putTrade.wait();
  // console.log("putTradeTx:", putTradeTx.hash);

  // const matchTrade = await Market.matchTrade(
  //   OrderType.buy,
  //   50n * 10n ** 18n,
  //   2n * 10n ** 5n,
  //   [0],
  //   { gasLimit: 500000 }
  // );
  // const matchTradeTx = await matchTrade.wait();
  // console.log("matchTradeTx:", matchTradeTx.hash);

  //

  config.Network = network.name;
  config.USDC = USDCAddress;
  config.DTT = DTTAddress;
  config.WETH = WETHAddress;
  config.DustCore = DustCoreAddress;
  config.DustPool = DustPoolAddress;
  (config.Governance = GovernanceAddress),
    (config.DustFlowFactory = DustFlowFactoryAddress),
    (config.DustFlowHelper = DustFlowHelperAddress);
  (config.market0 = getMarketInfo1[0]),
    (config.market1 = getMarketInfo2[0]),
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
