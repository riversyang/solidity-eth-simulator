var EthereumSimulator = artifacts.require("../contracts/EthereumSimulator");
var EthereumMiner1 = artifacts.require("../contracts/EthereumMiner");
var EthereumMiner2 = artifacts.require("../contracts/EthereumMiner");
var EthereumMiner3 = artifacts.require("../contracts/EthereumMiner");

contract('EthereumSimulator', function(accounts) {
    var simulatorInstance = EthereumSimulator.new();
    var minerInstance1 = EthereumMiner1.new({from: accounts[1], value: 20000000});
    var minerInstance2 = EthereumMiner2.new({from: accounts[2], value: 20000000});
    var minerInstance3 = EthereumMiner3.new({from: accounts[3], value: 20000000});

    it("Passes testcase 1 ", async function() {
        let defaultGas = 2000000;
        let simulator = await simulatorInstance;
        let miner1 = await minerInstance1;
        let miner2 = await minerInstance2;
        let miner3 = await minerInstance3;
        await miner1.register(simulator.contract.address, {from: accounts[1]});
        await miner2.register(simulator.contract.address, {from: accounts[2]});
        await miner3.register(simulator.contract.address, {from: accounts[3]});

        console.log("Miner1: " + miner1.contract.address);
        console.log("Miner2: " + miner2.contract.address);
        console.log("Miner3: " + miner3.contract.address);

        let result;
        result = await simulator.curMiner.call();
        console.log("Current Miner: " + result);
        assert.equal(result, miner1.contract.address);
        result = await simulator.totalStake.call();
        console.log(result.toNumber());
        assert.equal(result, 30000000);

        result = await simulator.processTransaction(100, 10, accounts[2], 1000, "test message.", {from: accounts[1]});
        console.log(result.logs);

        result = await miner1.getBalance.call(accounts[1]);
        console.log(result.toNumber());

        result = await miner1.getBalance.call(accounts[2]);
        console.log(result.toNumber());

        result = await simulator.curMiner.call();
        console.log("Current Miner: " + result);

        // result = await miner1.applyReward(100000000, {from: accounts[1]});
        // result = await miner1.getBalance.call(accounts[1]);
        // console.log(result.toNumber());
        // result = await miner1.addTransaction(accounts[1], 100, 10, accounts[2], 1000, "test message.", {from: accounts[1]});
        // console.log(result);
        // result = await miner1.finalizeBlock({from: accounts[1]});
        // result.logs.forEach(log => {
        //     console.log("_nonce: " + log.args._nonce);
        //     console.log("_from: " + log.args._from);
        //     console.log("_to: " + log.args._to);
        //     console.log("_value: " + log.args._value.toNumber());
        // });
    });

});
