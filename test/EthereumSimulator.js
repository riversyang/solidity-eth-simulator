var EthereumSimulator = artifacts.require("../contracts/EthereumSimulator");
var EthereumMiner1 = artifacts.require("../contracts/EthereumMiner");
var EthereumMiner2 = artifacts.require("../contracts/EthereumMiner");
var EthereumMiner3 = artifacts.require("../contracts/EthereumMiner");

contract('EthereumSimulator', function(accounts) {
    var simulatorInstance = EthereumSimulator.deployed();
    var minerInstance1 = EthereumMiner1.new({from: accounts[1], value: 30000000, gas: 3000000});
    var minerInstance2 = EthereumMiner2.new({from: accounts[2], value: 30000000, gas: 3000000});
    var minerInstance3 = EthereumMiner3.new({from: accounts[3], value: 30000000, gas: 3000000});

    it("Passes testcase 1 ", async function() {
        let defaultGas = 2000000;
        let simulator = await simulatorInstance;
        let miner1 = await minerInstance1;
        let miner2 = await minerInstance2;
        let miner3 = await minerInstance3;
        await miner1.register(simulator.contract.address, {from: accounts[1]});
        await miner2.register(simulator.contract.address, {from: accounts[2]});
        await miner3.register(simulator.contract.address, {from: accounts[3]});

        let result;
        result = await simulator.curMiner.call();
        console.log(result);
        assert.equal(result, miner1.contract.address);
        result = await simulator.totalStake.call();
        console.log(result.toNumber());
        assert.equal(result, 90000);
        // let result;
        // result = await instance.logMyData({gas: defaultGas});
        // result.logs.forEach(log => {
        //     console.log("_data: " + log.args._data);
        //     console.log("_length: " + log.args._length.toNumber());
        // });
    });

});
