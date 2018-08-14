pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/math/SafeMath.sol";

contract EthereumChainData {
    // 使用 SafeMath
    using SafeMath for uint256;
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
        Transaction txData;
    }
    // 区块链数据
    struct ChainData {
        Block[] blocks;
        mapping(bytes32 => uint256) transactions;
    }

    event LogTransactionData(
        bytes32 indexed _txHash,
        address indexed _from,
        uint256 _nonce,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _to,
        uint256 _value,
        bytes _data
    );

    // Chain data
    ChainData internal chainData;

    function getLatestBlockHash() public view returns (bytes32) {
        uint256 blockCount = chainData.blocks.length;
        require(blockCount > 0);
        BlockHeader storage latestHeader = chainData.blocks[blockCount - 1].header;
        bytes memory headerData = abi.encodePacked(
            latestHeader.parentHash,
            latestHeader.beneficiary,
            latestHeader.stateRoot,
            latestHeader.transactionsRoot,
            latestHeader.difficulty,
            latestHeader.number,
            latestHeader.gasLimit,
            latestHeader.gasUsed,
            latestHeader.timeStamp,
            latestHeader.extraData
        );
        return keccak256(headerData);
    }

    function getLatestTransactionHash() public view returns (bytes32) {
        uint256 blockCount = chainData.blocks.length;
        require(blockCount > 0);
        Transaction storage latestTx = chainData.blocks[blockCount - 1].txData;
        bytes memory txData = abi.encodePacked(
            latestTx.from,
            latestTx.nonce,
            latestTx.gasLimit,
            latestTx.gasPrice,
            latestTx.to,
            latestTx.value,
            latestTx.data
        );
        return keccak256(txData);
    }

    /**
     * @dev 取得当前链中的区块数量（最大区块号）
     * @notice 
     */
    function getDifficulty() public view returns (uint256)
    {
        uint256 blockCount = chainData.blocks.length;
        require(blockCount > 0);
        return chainData.blocks[blockCount - 1].header.difficulty.add(10);
    }

    function emitLogTransaction(bytes32 _txHash) public {
        uint256 txIndex = chainData.transactions[_txHash];
        require(txIndex > 0);
        Transaction storage curTx = chainData.blocks[txIndex].txData;
        emit LogTransactionData(_txHash, curTx.from, curTx.nonce, curTx.gasLimit, curTx.gasPrice, curTx.to, curTx.value, curTx.data);
    }

}