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

  const testToken = await ethers.getContractFactory("TestToken");
  const USDC = await testToken.deploy(
    "DustFlow Test USDC",
    "USDC"
  );
  const USDCAddress = await USDC.target;

  const DUST = await testToken.deploy(
    "DUST Stablecoin",
    "DUST"
  );
  const DUSTAddress = await DUST.target;


  const dustPool = await ethers.getContractFactory("DustPool");
  const DustPool = await dustPool.deploy(
    owner.address, 
    owner.address, 
    DUSTAddress,
    USDCAddress
);
  const DustPoolAddress = await DustPool.target;
  //   const DustPoolAddress = "";
  //   const DustPool = new ethers.Contract(DustPoolAddress, DustPoolABI.abi, owner);
  console.log("DustPool Address:", DustPoolAddress);

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
    DUSTAddress,
    DustPoolAddress,
    ethers.parseEther("1000000000")
  );

  const transfer0 = await USDC.transfer(DustPoolAddress, ethers.parseEther("100"));
  const transfer0Tx = await transfer0.wait();
  console.log("transfer0:", transfer0Tx.hash);

  const deposite1 = await DustPool.deposite(
    ethers.parseEther("100")
  );
  const deposite1Tx = await deposite1.wait();
  console.log("deposite1:", deposite1Tx.hash);

  const getUserInfo1 = await DustPool.getUserInfo(owner.address);
  console.log("getUserInfo1:", getUserInfo1);

  const getAmounts0 = await DustPool.getAmounts(owner.address);
  console.log("getAmounts0:", getAmounts0);
  
  const transfer1 = await USDC.transfer(DustPoolAddress, ethers.parseEther("100"));
  const transfer1Tx = await transfer1.wait();
  console.log("transfer1:", transfer1Tx.hash);
  
  const dustBalance1 = await DustPool.getTokenBalance(DUSTAddress, DustPoolAddress);
  console.log("Dust Balance1:", dustBalance1);

  const usdcBalance1 = await DustPool.getTokenBalance(USDCAddress, DustPoolAddress);
  console.log("Usdc Balance1:", usdcBalance1);

  const getAmounts1 = await DustPool.getAmounts(owner.address);
  console.log("getAmounts1:", getAmounts1);

  const deposite2 = await DustPool.deposite(
    ethers.parseEther("100")
  );
  const deposite2Tx = await deposite2.wait();
  console.log("deposite2:", deposite2Tx.hash);

  const getUserInfo2 = await DustPool.getUserInfo(owner.address);
  console.log("getUserInfo2:", getUserInfo2);

  const transfer = await USDC.transfer(DustPoolAddress, ethers.parseEther("100"));
  const transferTx = await transfer.wait();
  console.log("Transfer tx:", transferTx.hash);

  const getAmounts2 = await DustPool.getAmounts(owner.address);
  console.log("getAmounts2:", getAmounts2);

  const dustBalance2 = await DustPool.getTokenBalance(DUSTAddress, DustPoolAddress);
  console.log("Dust Balance2:", dustBalance2);
  const usdcBalance2 = await DustPool.getTokenBalance(USDCAddress, DustPoolAddress);
  console.log("Usdc Balance2:", usdcBalance2);

  const withdraw = await DustPool.withdraw();
  const withdrawTx = await withdraw.wait();
  console.log("withdraw:", withdrawTx.hash);

  const getUserInfo3 = await DustPool.getUserInfo(owner.address);
  console.log("getUserInfo3:", getUserInfo3);
  
  const getAmounts3 = await DustPool.getAmounts(owner.address);
  console.log("getAmounts3:", getAmounts3);

  const dustBalance3 = await DustPool.getTokenBalance(DUSTAddress, DustPoolAddress);
  console.log("Dust Balance3:", dustBalance3);

  const usdcBalance3 = await DustPool.getTokenBalance(USDCAddress, DustPoolAddress);
  console.log("Usdc Balance3:", usdcBalance3);

  const deposite3 = await DustPool.deposite(
    ethers.parseEther("100")
  );
  const deposite3Tx = await deposite3.wait();
  console.log("deposite3:", deposite3Tx.hash);

  const getUserInfo4 = await DustPool.getUserInfo(owner.address);
  console.log("getUserInfo4:", getUserInfo4);

  const transfer4 = await USDC.transfer(DustPoolAddress, ethers.parseEther("100"));
  const transfer4Tx = await transfer4.wait();
  console.log("Transfer4 tx:", transfer4Tx.hash);

  const totalShare = await DustPool.totalShare();
  console.log("totalShare:", totalShare);

  const extracted = await DustPool.extracted();
  console.log("extracted:", extracted);

  const getAmounts4 = await DustPool.getAmounts(owner.address);
  console.log("getAmounts4:", getAmounts4);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
