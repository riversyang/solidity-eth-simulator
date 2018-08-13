pragma solidity ^0.4.24;

library EthereumChainData {
    // 交易数据
    struct Transaction {
        address from;
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
        Transaction[] transactions;
    }
    // 区块链数据
    struct ChainData {
        Block[] blocks;
    }

    /**
     * @dev 取得当前链中的区块数量（最大区块号）
     * @notice 
     */
    function getChainLength(ChainData storage self) public view returns (uint256)
    {
        return self.blocks.length;
    }

    function appendBlockFromBytes(ChainData storage self, bytes _blockData) public {

    }

}