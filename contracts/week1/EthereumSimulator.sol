pragma solidity ^0.4.24;

import "./EthereumWorldState.sol";
import "./EthereumChainData.sol";

contract EthereumSimulator {
    // 世界状态
    using EthereumWorldState for EthereumWorldState.StateData;
    EthereumWorldState.StateData worldState;
    // 节点类型
    enum NodeType {Unknown, FullNode, Miner}
    mapping (address => NodeType) private nodesType;
    // 记录所有矿工地址的数组
    address[] private miners;
    // 所有矿工账户的余额总和
    uint256 private totalStake;

    /**
     * @dev 创建 Genesis Block，因这个模拟合约会采用一个简化的 PoS 算法来确定矿工，所以需要在构造函数中
     * 为创建合约的地址创建账户，并将其指定为第一个矿工，以保证合约的运作
     * @notice 
     */
    constructor() public payable {
        bytes memory codeBinary = new bytes(0);
        createAccount(codeBinary);
        miners.push(msg.sender);
        totalStake = msg.value;
    }

    /**
     * @dev 调用内部函数模拟客户端的创建账户操作
     * @param _codeBinary 模拟随账户创建的 EVM 代码，可以使用任意字节数据
     * @notice 此函数需要标记为 payable，以便转入一定量的 Ether 作为公用的账户余额
     */
    function createAccount(bytes _codeBinary) public payable {
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
     * @dev 模拟客户端节点的注册模式
     * @param asMiner 是否作为矿工节点
     * @notice 
     */
    function registerNode(bool _asMiner) external {
        if (_asMiner == true) {
            if (nodesType[msg.sender] != NodeType.Miner) {
                uint256 minerStake = worldState.getBalance(msg.sender);
                if (minerStake == 0) {
                    revert("Please deposit some ethers before registering as a miner.");
                }
                nodesType[msg.sender] = NodeType.Miner;
                miners.push(msg.sender);
                totalStake += minerStake;
            }
        } else {
            nodesType[msg.sender] = NodeType.FullNode;
        }
    }

    /**
     * @dev 简化地模拟交易的处理
     * @notice 
     */
    function processTransaction() external {

    }
}