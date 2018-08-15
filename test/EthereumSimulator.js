var EthereumSimulator = artifacts.require("../contracts/EthereumSimulator");
var Miner1 = artifacts.require("../contracts/Miner1");
var Miner2 = artifacts.require("../contracts/Miner2");
var Miner3 = artifacts.require("../contracts/Miner3");

contract('EthereumSimulator', function(accounts) {
    var simulatorInstance = EthereumSimulator.deployed();
    var minerInstance1;
    Miner1.deployed().then(miner1 => {
        const events1 = miner1.allEvents({fromBlock: 0, toBlock: "latest"});
        events1.watch(function(error, result) {
            if (!error) {
                console.log("Miner1 event " + result.event + " detected: ");
                console.log("   _txHash: " + result.args._txHash);
                console.log("   _from: " + result.args._from);
                console.log("   _nonce: " + result.args._nonce);
                console.log("   _gasLimit: " + result.args._gasLimit.toNumber());
                console.log("   _gasPrice: " + result.args._gasPrice.toNumber());
                console.log("   _to: " + result.args._to);
                console.log("   _value: " + result.args._value);
                console.log("   _data: " + result.args._data);
            } else {
                console.log("Error occurred while watching events.");
            }
        });
        minerInstance1 = miner1;
    });
    var minerInstance2;
    Miner2.deployed().then(miner2 => {
        const events2 = miner2.allEvents({fromBlock: 0, toBlock: "latest"});
        events2.watch(function(error, result) {
            if (!error) {
                console.log("Miner2 event " + result.event + " detected: ");
                console.log("   _txHash: " + result.args._txHash);
                console.log("   _from: " + result.args._from);
                console.log("   _nonce: " + result.args._nonce);
                console.log("   _gasLimit: " + result.args._gasLimit.toNumber());
                console.log("   _gasPrice: " + result.args._gasPrice.toNumber());
                console.log("   _to: " + result.args._to);
                console.log("   _value: " + result.args._value);
                console.log("   _data: " + result.args._data);
            } else {
                console.log("Error occurred while watching events.");
            }
        });
        minerInstance2 = miner2;
    });
    var minerInstance3;
    Miner3.deployed().then(miner3 => {
        const events3 = miner3.allEvents({fromBlock: 0, toBlock: "latest"});
        events3.watch(function(error, result) {
            if (!error) {
                console.log("Miner3 event " + result.event + " detected: ");
                console.log("   _txHash: " + result.args._txHash);
                console.log("   _from: " + result.args._from);
                console.log("   _nonce: " + result.args._nonce);
                console.log("   _gasLimit: " + result.args._gasLimit.toNumber());
                console.log("   _gasPrice: " + result.args._gasPrice.toNumber());
                console.log("   _to: " + result.args._to);
                console.log("   _value: " + result.args._value);
                console.log("   _data: " + result.args._data);
            } else {
                console.log("Error occurred while watching events.");
            }
        });
        minerInstance3 = miner3;
    });

    it("Passes testcase 1 ", async function() {
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
