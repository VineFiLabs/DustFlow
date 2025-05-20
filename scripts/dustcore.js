const hre = require("hardhat");
const fs = require("fs");
const DustAaveCoreABI = require("../artifacts/contracts/core/DustAaveCore.sol/DustAaveCore.json");
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
  const DustPoolAddress = Set[chainId].DustPool;
  console.log("DustPool:", DustPoolAddress);
  const DustCoreAddress = Set[chainId].DustCore;
  console.log("DustCore:", DustCoreAddress);
  const USDCAddress = Set[chainId].USDC;
  console.log("USDC:", USDCAddress);
  const DustAaveCore = new ethers.Contract(
    DustCoreAddress,
    DustAaveCoreABI.abi,
    owner
  );

  const changeFeeInfo = await DustAaveCore.setFeeInfo(
    5000,
    owner.address,
    DustPoolAddress,
    {
      gasLimit: 100000,
    }
  );
  const changeFeeInfoTx = await changeFeeInfo.wait();
  console.log("changeFeeInfoTx:", changeFeeInfoTx.hash);

  
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
