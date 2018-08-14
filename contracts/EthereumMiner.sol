pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./openzeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol";
import "./EthereumChainData.sol";
import "./EthereumWorldState.sol";

contract EthereumMiner is SupportsInterfaceWithLookup {
    // 对所有 uint256 类型使用 SafeMath
    using SafeMath for uint256;
    // 默认的区块 gasLimit 常量
    uint256 public constant BLOCK_GAS_LIMIT = 100;
    // 世界状态
    using EthereumWorldState for EthereumWorldState.StateData;
    // State DB
    mapping(uint256 => EthereumWorldState.StateData) private stateDB;
    // Chain data
    EthereumChainData.ChainData private chainData;
    // 交易池
    EthereumChainData.Transaction[] internal transactionsPool;
    // 当前已消耗 gas 累计
    uint256 public gasUsed;
    // 是否正在记账
    bool private isCurrentMiner;

    /**
     * @dev 创建矿工合约，需要以太坊协议模拟器合约已创建
     * @notice 创建时需要存入一定量的资金
     */
    constructor() public payable {
        require(msg.value > 0);
        _registerInterface(bytes4(keccak256("addTransaction(address,uint256,uint256,uint256,address,uint256,bytes)")));
        _registerInterface(bytes4(keccak256("finalizeBlock()")));
    }

    modifier isAccounting() {
        require(isCurrentMiner);
        _;
    }

    modifier isNotAccounting() {
        require(!isCurrentMiner);
        _;
    }

    function createBlock() external isNotAccounting {
        EthereumChainData.Block storage newBlock;
        EthereumWorldState.StateData storage newState;
        
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
        returns (bool)
    {
        // 需要创世区块创建之后才能开始处理交易
        require(chainData.blocks.length > 0);
        // 交易的 gasLimit 需要小于区块的 gasLimit
        require(_gasLimit <= BLOCK_GAS_LIMIT);
        // 交易的实际 gas 消耗需要小于交易自己指定的 gasLimit
        require(_data.length <= _gasLimit);
        // 获取当前的 World State
        EthereumWorldState.StateData storage curState = stateDB[uint256(chainData.blocks.length - 1)];
        // 交易发送者账户的余额需要大于交易实际要消耗的 gas * gasPrice
        require(uint256(_data.length).mul(_gasPrice) <= curState.getBalance(_from));

        if (gasUsed + _data.length > BLOCK_GAS_LIMIT) {
            return false;
        } else {
            uint256 _nonce = curState.addNonce(_from);
            EthereumChainData.Transaction memory transaction = EthereumChainData.Transaction({
                from: _from, nonce: _nonce, gasLimit: _gasLimit, gasPrice: _gasPrice, to: _to,
                value: _value, data: _data
            });
            transactionsPool.push(transaction);
            gasUsed += _data.length;
            return true;
        }
    }

    function finalizeBlock() external isAccounting returns (bytes) {
        // 执行交易池中的所有交易
    }

    function applyBlock(bytes _blockData) external isNotAccounting {

    }

}