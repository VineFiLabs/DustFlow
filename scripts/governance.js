const hre = require("hardhat");
const fs = require("fs");
const GovernanceABI = require("../artifacts/contracts/core/Governance.sol/Governance.json");
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
  const GovernanceAddress = Set[chainId].Governance;
  console.log("Governance:", GovernanceAddress);
  const USDCAddress = Set[chainId].USDC;
  console.log("USDC:", USDCAddress);
  const Governance = new ethers.Contract(
    GovernanceAddress,
    GovernanceABI.abi,
    owner
  );

  const changeFeeInfo = await Governance.changeFeeInfo(
    owner.address,
    DustPoolAddress,
    50,
    {
      gasLimit: 100000,
    }
  );
  const changeFeeInfoTx = await changeFeeInfo.wait();
  console.log("changeFeeInfoTx:", changeFeeInfoTx.hash);

// const changeCollateral0 = await Governance.changeCollateral(
//     0,
//     USDCAddress,
//     {
//       gasLimit: 100000,
//     }
//   );
//   const changeCollateral0Tx = await changeCollateral0.wait();
//   console.log("changeCollateral0:", changeCollateral0Tx.hash);

//   const changeCollateral1 = await Governance.changeCollateral(
//     0,
//     USDCAddress,
//     {
//       gasLimit: 100000,
//     }
//   );
//   const changeCollateral1Tx = await changeCollateral1.wait();
//   console.log("changeCollateral1:", changeCollateral1Tx.hash);

  
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
