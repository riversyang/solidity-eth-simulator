pragma solidity ^0.4.24;

import "../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./EthereumWorldState.sol";
import "./EthereumChainData.sol";
import "./EthereumMiner.sol";

contract EthereumSimulator is Ownable {
    // 对所有 uint256 类型使用 SafeMath
    using SafeMath for uint256;
    // 默认的区块 gasLimit 常量
    uint256 public constant BLOCK_GAS_LIMIT = 100;
    // 世界状态
    using EthereumWorldState for EthereumWorldState.StateData;
    EthereumWorldState.StateData private worldState;
    // 区块链数据
    EthereumChainData.ChainData private chainData;
    // 记录所有矿工地址的数组
    address[] private allMiners;
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
    constructor() payable public {
        bytes memory codeBinary = new bytes(0);
        createAccount(codeBinary);
        allMiners.push(msg.sender);
        totalStake = msg.value;
    }

    /**
     * @dev 调用内部函数模拟客户端的创建账户操作
     * @param _codeBinary 模拟随账户创建的 EVM 代码，可以使用任意字节数据
     * @notice 此函数需要标记为 payable，以便转入一定量的 Ether 作为公用的账户余额
     */
    function createAccount(bytes _codeBinary) payable public {
        worldState.createAccount(msg.sender, msg.value, _codeBinary);
    }

    /**
     * @dev 获取指定账户的余额
     * @param _addr 给定的账户地址
     */
    function getAccountBalance(address _addr) view public returns(uint256) {
        return worldState.getBalance(_addr);
    }

    /**
     * @dev 为了简化处理，只允许由合约创建者添加矿工合约地址
     * （避免由于需要在 Miner 合约中调用此函数来注册所导致的循环引用的情况）
     * @param _addr 要添加的矿工节点地址
     * @notice 
     */
    function addMiner(address _addr) external onlyOwner {
        // 检查目标合约是否实现了必要的矿工合约函数
        SupportsInterfaceWithLookup siwl = SupportsInterfaceWithLookup(_addr);
        require(siwl.supportsInterface(bytes4(keccak256("addTransaction(address,uint256,uint256,uint256,address,uint256,bytes)"))));
        require(siwl.supportsInterface(bytes4(keccak256("finalizeBlock()"))));

        if (allMiners.length == 0 || allMinersIndex[_addr] == 0 && _addr != allMiners[0]) {
            uint256 minerStake = worldState.getBalance(_addr);
            if (minerStake == 0) {
                revert("Please deposit some ethers before registering as a miner.");
            }
            allMinersIndex[_addr] = allMiners.length;
            allMiners.push(_addr);
            totalStake += minerStake;
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
            totalStake -= worldState.getBalance(_addr);
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
     * @dev 简化地模拟交易的处理
     * @notice 
     */
    function processTransaction(
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _to,
        uint256 _value,
        bytes _data
    )
        external
    {
        // 需要创世区块创建之后才能开始处理交易
        require(EthereumChainData.getChainLength(chainData) > 0);
        // 交易的 gasLimit 需要小于区块的 gasLimit
        require(_gasLimit <= BLOCK_GAS_LIMIT);
        // 交易的实际 gas 消耗需要小于交易自己指定的 gasLimit
        require(_data.length <= _gasLimit);
        // 交易发送者账户的余额需要大于交易实际要消耗的 gas * gasPrice
        require(_data.length.mul(_gasPrice) <= worldState.getBalance(msg.sender));

        EthereumMiner cm = EthereumMiner(curMiner);
        // 简化的处理，以 _data 的长度作为要消耗的 gas 数量
        uint256 curTxGas = _data.length;
        if (curTxGas.add(cm.gasUsed()) >= BLOCK_GAS_LIMIT) {
            // 如果当前区块的剩余 gas 已经不够处理这个交易，则将当前区块定稿
            bytes memory blockData = cm.finalizeBlock();
            EthereumChainData.appendBlockFromBytes(chainData, blockData);
            // 选出下一个矿工
            curMiner = selectNewMiner();
            cm = EthereumMiner(curMiner);
        }
        // 将交易加入矿工的交易池中
        cm.addTransaction(msg.sender, worldState.addNonce(msg.sender),
            _gasLimit, _gasPrice, _to, _value, _data
        );
    }

    /**
     * @dev 基于简化的 PoS 算法选出下一个矿工地址
     * @notice 
     */
    function selectNewMiner() private returns(address) {

    }

}