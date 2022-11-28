require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-web3");

const { privateKey } = require('./private/secrets.json');


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",

  networks: {
    hardhat: {
    },
    robin: {
      url: "https://robin.rangersprotocol.com/api/jsonrpc",
      chainId: 9527,
      accounts: [ privateKey ]    // 0x17a99B62Eb6Db79D2b791eA895Dd61A404074C39
    }
  },

  solidity: {
    compilers:  [
      {
        version: "0.6.12",
        settings: { optimizer: { enabled: true, runs: 200 } }
      },
      {
        version: "0.8.10",
        settings: { optimizer: { enabled: true, runs: 200 } }
      },
      {
        version: "0.8.12",
        settings: { optimizer: { enabled: true, runs: 200 } }
      },
    ],
  }
};
