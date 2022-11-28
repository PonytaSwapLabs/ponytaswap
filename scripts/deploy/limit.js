// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.

const hre = require("hardhat");
const { web3, ethers } = require("hardhat");

async function main() {

    const accs = await web3.eth.getAccounts()
    const admin = accs[0]
    console.log("====> admin:", admin)
    
    const LimitOrderProtocol = await hre.ethers.getContractFactory("LimitOrderProtocol");
    const cc = await LimitOrderProtocol.deploy();
    await cc.deployed();
    console.log("[√] deployed LimitOrderProtocol:", cc.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
