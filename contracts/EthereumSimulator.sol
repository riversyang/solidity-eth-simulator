pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./EthereumWorldState.sol";
import "./EthereumChainData.sol";
import "./EthereumMiner.sol";

contract EthereumSimulator is Ownable {
    // 对所有 uint256 类型使用 SafeMath
    using SafeMath for uint256;
    // 默认的区块 gasLimit 常量
    uint256 public constant BLOCK_GAS_LIMIT = 100;
    // 区块链数据
    EthereumChainData.ChainData private chainData;
    // 记录所有矿工地址的数组
    address[] private allMiners;
    // 矿工地址到其 Stake 数值的映射
    mapping (address => uint256) private minerStakes;
    // 矿工地址到其在 allMiners 数组中索引的映射
    mapping (address => uint256) private allMinersIndex;
    // 当前矿工地址
    address private curMiner;
    // 所有矿工账户的余额总和
    uint256 private totalStake;

    /**
     * @dev 创建 Genesis Block，因这个模拟合约会采用一个简化的 PoS 算法来确定矿工，所以需要在构造函数中
     * 为创建合约的地址创建账户，并将其指定为第一个矿工，以保证合约的运作
     * @notice 
     */
    constructor() public payable {
        bytes memory codeBinary = new bytes(0);
        minerStakes[msg.sender] = msg.value;
        allMiners.push(msg.sender);
        totalStake = msg.value;
    }

    /**
     * @dev 为了简化处理，只允许由合约创建者添加矿工合约地址
     * （避免由于需要在 Miner 合约中调用此函数来注册所导致的循环引用的情况）
     * @param _addr 要添加的矿工节点地址
     * @notice 
     */
    function addMiner(address _addr, uint256 _stake) external onlyOwner {
        // 检查目标合约是否实现了必要的矿工合约函数
        SupportsInterfaceWithLookup siwl = SupportsInterfaceWithLookup(_addr);
        require(siwl.supportsInterface(bytes4(keccak256("addTransaction(address,uint256,uint256,uint256,address,uint256,bytes)"))));
        require(siwl.supportsInterface(bytes4(keccak256("finalizeBlock()"))));

        if (allMiners.length == 0 || allMinersIndex[_addr] == 0 && _addr != allMiners[0]) {
            if (_stake == 0) {
                revert("Please deposit some ethers before registering as a miner.");
            }
            allMinersIndex[_addr] = allMiners.length;
            allMiners.push(_addr);
            totalStake += _stake;
            minerStakes[_addr] = _stake;
        }
    }

    /**
     * @dev 为了简化处理，只允许由合约创建者移除矿工合约地址
     * （避免由于需要在 Miner 合约中调用此函数来注册所导致的循环引用的情况）
     * @param _addr 要移除的矿工节点地址
     * @notice 
     */
    function removeMiner(address _addr) external onlyOwner {
        // 至少需要保留一个矿工
        require(allMiners.length > 1, "The simulator needs at least one miner to work.");

        uint256 minerIndex = allMinersIndex[_addr];
        if (minerIndex > 0 || _addr == allMiners[0]) {
            uint256 lastMinerIndex = allMiners.length.sub(1);
            address lastMiner = allMiners[lastMinerIndex];
            allMiners[minerIndex] = lastMiner;
            allMiners[lastMinerIndex] = 0;
            allMiners.length--;
            allMinersIndex[_addr] = 0;
            totalStake -= minerStakes[_addr];
            minerStakes[_addr] = 0;
        }
    }

    /**
     * @dev 只允许由合约创建者调用的创建创世区块的处理
     * （也就是正式启动以太坊模拟器）
     */
    function createGenesisBlock() external onlyOwner {
        require(allMiners.length > 0, "To start the simulator, you need to add at least one miner.");
    }

    /**
     * @dev 向当前矿工发送一个交易
     * @notice 
     */
    function sendTransaction(
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _to,
        uint256 _value,
        bytes _data
    )
        external
    {
        require(_data.length <= BLOCK_GAS_LIMIT);
        EthereumMiner cm = EthereumMiner(curMiner);
        if (!cm.addTransaction(msg.sender, _gasLimit, _gasPrice, _to, _value, _data)) {
            bytes memory blockData = cm.finalizeBlock();
            for (uint256 i = 0; i < allMiners.length; i++) {
                if (allMiners[i] != curMiner) {
                    cm = EthereumMiner(allMiners[i]);
                    cm.applyBlock(blockData);
                }
            }
            selectNewMiner();
            EthereumMiner(curMiner).addTransaction(msg.sender, _gasLimit, _gasPrice, _to, _value, _data);
        }
    }

    /**
     * @dev 基于简化的 PoS 算法选出下一个矿工地址
     * @notice 
     */
    function selectNewMiner() private {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp))) % totalStake;
        uint256 tmpSum;
        address curAddress;
        uint minersCount = allMiners.length;
        for (uint i = 0; i < minersCount; i++) {
            curAddress = allMiners[i];
            tmpSum = tmpSum.add(minerStakes[curAddress]);
            if (tmpSum > rand) {
                curMiner = curAddress;
                break;
            }
        }
    }

}