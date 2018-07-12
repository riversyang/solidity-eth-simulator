pragma solidity ^0.4.24;

library EthereumChainData {
    // 默认的区块 gasLimit 常量
    uint256 constant BLOCK_GAS_LIMIT = 100;
    // 交易数据
    struct Transaction {
        uint256 nonce;
        uint256 gasLimit;
        uint256 gasPrice;
        address to;
        uint256 value;
        bytes data;
    }
    // 区块头数据
    struct BlockHeader {
        bytes32 parentHash;
        address beneficiary;
        bytes32 stateRoot;
        bytes32 transactionsRoot;
        uint256 difficulty;
        uint256 number;
        uint256 gasLimit;
        uint256 gasUsed;
        uint256 timeStamp;
        bytes32 extraData;
    }
    // 区块数据
    struct Block {
        BlockHeader header;
        mapping(uint256 => Transaction) transactionsTrie;
    }
    // 区块链数据
    struct ChainData {
        Block[] blocks;
    }

}