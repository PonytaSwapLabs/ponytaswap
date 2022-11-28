const hre = require("hardhat");
const { web3, ethers } = require("hardhat");


// npx hardhat run .\scripts\deploy\uniswapv2.js --network hardhat
async function main() {
    const accs = await web3.eth.getAccounts()
    const admin = accs[0]
    console.log("====> admin:", admin)

    const WETH = await hre.ethers.getContractFactory("MockTokenWETH");
    const weth = await WETH.deploy();
    await weth.deployed();
    console.log("[√] deployed MockTokenWETH:", weth.address);

    const Unv2Factory = await hre.ethers.getContractFactory("UniswapV2Factory");
    const factory = await Unv2Factory.deploy(admin);
    await factory.deployed();
    console.log("[√] deployed UniswapV2Factory:", factory.address);

    const Unv2Router = await hre.ethers.getContractFactory("UniswapV2Router02");
    const router = await Unv2Router.deploy(factory.address, weth.address);
    await router.deployed();
    console.log("[√] deployed UniswapV2Router02:", router.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
