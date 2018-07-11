pragma solidity ^0.4.24;

import "./datastructs/Account.sol";

contract EthereumSimulator {
    using Account for Account.AccountState;

    // 空字符串的 keccak256 哈希值，作为那些没有附加代码的账户的状态数据中 codeHash 字段的值
    bytes32 constant EMPTY_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // 全局的状态树，key 为 keccak256(address)，value 为 Account.AccountState 的序列化数据
    mapping (bytes32 => bytes) stateTrie;
    // 全局的账户代码存储，key 为 keccak256(address)，value 为用于模拟账户代码的字节数据
    mapping (bytes32 => bytes) codeROM;

    address[] miners;
    uint256 totalStake;

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
     * @dev 模拟客户端的创建账户操作，使用调用者地址作为新账户的地址
     * @param codeBinary 模拟随账户创建的 EVM 代码，可以使用任意字节数据
     * @notice 此函数需要标记为 payable，以便转入一定量的 Ether 作为公用的账户余额
     */
    function createAccount(bytes codeBinary) public payable {
        bytes32 codeHash;

        if (codeBinary.length > 0) {
            // 计算传入代码的 code 哈希
            codeHash = keccak256(codeBinary);
        } else {
            // 使用常数作为 code 哈希
            codeHash = EMPTY_HASH;
        }

        // TODO：初始化账户状态数据，并将其加入 stateTrie
        Account.AccountState memory accountState = Account.AccountState({
            nonce: 0, balance: msg.value, storageRoot: 0x0, codeHash: codeHash
        });
        stateTrie[keccak256(abi.encodePacked(msg.sender))] = accountState.toBytes();
    }
}