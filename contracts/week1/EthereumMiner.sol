pragma solidity ^0.4.24;

import "./EthereumSimulator.sol";
import "./EthereumChainData.sol";

contract EthereumMiner {
    // 以太坊协议模拟器引用
    EthereumSimulator private ethereumSim;
    // 交易池
    EthereumChainData.Transaction[] private transactionsPool;
    // 当前已消耗 gas 累计
    uint256 public gasUsed;

    /**
     * @dev 创建矿工合约，需要以太坊协议模拟器合约已创建
     * @param _ethSim 以太坊协议模拟器合约地址
     * @notice 创建时需要存入一定量的资金
     */
    constructor(EthereumSimulator _ethSim) public payable {
        require(msg.value > 0);
        ethereumSim = _ethSim;
    }

    /**
     * @dev 简化地模拟交易的处理
     * @notice 
     */
    function addTransaction(
        address _from,
        uint256 _nonce,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _to,
        uint256 _value,
        bytes _data
    )
        external
    {
        EthereumChainData.Transaction memory trasaction = EthereumChainData.Transaction({
            from: _from, nonce: _nonce, gasLimit: _gasLimit, gasPrice: _gasPrice, to: _to,
            value: _value, data: _data
        });
        transactionsPool.push(trasaction);
        gasUsed += _data.length;
    }

    function finalizeBlock() external returns(bytes memory _blockData) {

    }

}