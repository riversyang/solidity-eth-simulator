pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./openzeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol";
import "./EthereumChainData.sol";
import "./EthereumWorldState.sol";

contract EthereumMiner is 
    SupportsInterfaceWithLookup, EthereumChainData, EthereumWorldState, Ownable
{
    // 默认的区块 gasLimit 常量
    uint256 public constant BLOCK_GAS_LIMIT = 100;
    // 交易池
    EthereumChainData.Transaction[] private transactionsPool;
    // 当前已消耗 gas 累计
    uint256 public gasUsed;
    // 是否正在记账
    bool private isCurrentMiner;
    // 以太坊网络模拟器
    EthereumSimulatorBase private networkSimulator;

    /**
     * @dev 创建矿工合约，需要以太坊协议模拟器合约已创建
     * @notice 创建时需要存入一定量的资金
     */
    constructor() public payable {
        require(msg.value > 0);
        _registerInterface(bytes4(keccak256("addTransaction(address,uint256,uint256,address,uint256,bytes)")));
        _registerInterface(bytes4(keccak256("finalizeBlock()")));

        createGenesisBlock();
    }

    modifier isAccounting() {
        require(isCurrentMiner);
        _;
    }

    modifier isNotAccounting() {
        require(!isCurrentMiner);
        _;
    }

    modifier onlyFromSimulator() {
        require(
            address(msg.sender) == address(networkSimulator),
            "Only accept calling from Network Simulator."
        );
        _;
    }

    function register(address _addr) external isNotAccounting onlyOwner {
        networkSimulator = EthereumSimulatorBase(_addr);
        uint256 _value = address(this).balance / 2;
        require(
            networkSimulator.registerMiner.value(_value)(),
            "Failed to register miner."
        );
    }

    function unregister() external isNotAccounting onlyOwner {
        require(
            networkSimulator.unregisterMiner(),
            "Failed to unregister miner."
        );
    }

    function applyReward(uint256 _reward) external onlyFromSimulator {
        addBalance(address(this), _reward);
    }

    function prepareToCreateBlock() external isNotAccounting onlyFromSimulator {
        isCurrentMiner = true;
    }

    /**
     * @dev 简化地模拟交易的处理
     * @notice 
     */
    function addTransaction(
        address _from,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _to,
        uint256 _value,
        bytes _data
    )
        external
        isAccounting
        onlyFromSimulator
        returns (bool)
    {
        // 需要创世区块创建之后才能开始处理交易
        require(chainData.blocks.length > 0);
        // 交易的 gasLimit 需要小于区块的 gasLimit
        require(_gasLimit <= BLOCK_GAS_LIMIT);
        // 交易的实际 gas 消耗需要小于交易自己指定的 gasLimit
        require(_data.length <= _gasLimit);
        // 交易发送者账户的余额需要大于交易实际要消耗的 gas * gasPrice
        require(uint256(_data.length).mul(_gasPrice) <= getBalance(_from));

        if (gasUsed + _data.length > BLOCK_GAS_LIMIT) {
            return false;
        } else {
            uint256 _nonce = addNonce(_from);
            Transaction memory transaction = Transaction({
                from: _from, nonce: _nonce, gasLimit: _gasLimit, gasPrice: _gasPrice, to: _to,
                value: _value, data: _data
            });
            transactionsPool.push(transaction);
            gasUsed += _data.length;
            return true;
        }
    }

    function finalizeBlock() external isAccounting onlyFromSimulator returns (bytes) {
        // 执行交易池中的所有交易
        require(transactionsPool.length > 0);
        Transaction memory transaction = Transaction({
            from: transactionsPool[0].from,
            nonce: transactionsPool[0].nonce,
            gasLimit: transactionsPool[0].gasLimit,
            gasPrice: transactionsPool[0].gasPrice,
            to: transactionsPool[0].to,
            value: transactionsPool[0].value,
            data: transactionsPool[0].data
        });
        BlockHeader memory header = initBlockHeader(header, transaction.data.length);
        Block memory newBlock = Block({header: header, txData: transaction});
        chainData.blocks.push(newBlock);
        emitLogTransaction(getLatestTransactionHash());
        delete transactionsPool;
        isCurrentMiner = false;
    }

    function applyBlock(bytes _blockData) external isNotAccounting onlyFromSimulator {

    }

    function initBlockHeader(BlockHeader memory _bHeader, uint256 _gasUsed)
        private view returns (BlockHeader)
    {
        _bHeader.parentHash = getLatestBlockHash();
        _bHeader.beneficiary = address(this);
        _bHeader.stateRoot = 0x0;
        _bHeader.transactionsRoot = 0x0;
        _bHeader.difficulty = getDifficulty();
        _bHeader.number = chainData.blocks.length;
        _bHeader.gasLimit = BLOCK_GAS_LIMIT;
        _bHeader.gasUsed = _gasUsed;
        _bHeader.timeStamp = block.timestamp;
        _bHeader.extraData = bytes32("Mined by simple miner.");
        return _bHeader;
    }

}

interface EthereumSimulatorBase {
    function registerMiner() external payable returns (bool);
    function unregisterMiner() external returns (bool);
}