var EthereumSimulator = artifacts.require("./EthereumSimulator.sol");

module.exports = function(deployer, accounts) {
    deployer.deploy(EthereumSimulator, {overwrite: true});
};
