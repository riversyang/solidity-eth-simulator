pragma solidity ^0.4.24;

import "../openzeppelin-solidity/contracts/math/SafeMath.sol";

library EthereumWorldState {
    // 对所有 uint256 类型使用 SafeMath
    using SafeMath for uint256;
    // 空字符串的哈希值常量
    bytes32 constant EMPTY_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // AccountState struct
    struct AccountState {
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }
    // StateTrie data struct
    struct StateData {
        mapping(address => AccountState) stateTrie;
        mapping(address => bytes) codeTrie;
    }
    // 虚拟机
    struct VM {
        bytes vmStack;
        bytes vmMemory;
    }

    function createAccount(
        StateData storage self,
        address _addr,
        uint256 _value,
        bytes _codeBinary
    )
        public
    {
        bytes32 _codeHash;

        if (_codeBinary.length > 0) {
            // 计算传入代码的 code 哈希
            _codeHash = keccak256(_codeBinary);
            self.codeTrie[_addr] = _codeBinary;
        } else {
            // 使用常数作为 code 哈希
            _codeHash = EMPTY_HASH;
        }

        self.stateTrie[_addr] = AccountState({
            nonce: 0, balance: _value,
            storageRoot: EMPTY_HASH, codeHash: _codeHash
        });
    }

    function hasCode(
        StateData storage self,
        address _addr
    )
        view
        public
        returns(bool)
    {
        return (self.stateTrie[_addr].codeHash ^ EMPTY_HASH != 0);
    }

    function addNonce(
        StateData storage self,
        address _addr
    )
        public
        returns(uint256)
    {
        self.stateTrie[_addr].nonce = self.stateTrie[_addr].nonce.add(1);
        return self.stateTrie[_addr].nonce;
    }

    function getBalance(
        StateData storage self,
        address _addr
    )
        view
        public
        returns(uint256)
    {
        return self.stateTrie[_addr].balance;
    }

    function addBalance(
        StateData storage self,
        address _addr,
        uint256 _value
    )
        public
        returns(uint256)
    {
        self.stateTrie[_addr].balance = self.stateTrie[_addr].balance.add(_value);
        return self.stateTrie[_addr].balance;
    }

    function subBalance(
        StateData storage self,
        address _addr,
        uint256 _value
    )
        public
        returns(uint256)
    {
        require(self.stateTrie[_addr].balance >= _value, "Balance is not enough.");
        self.stateTrie[_addr].balance = self.stateTrie[_addr].balance.sub(_value);
        return self.stateTrie[_addr].balance;
    }

    function getCode(
        StateData storage self,
        address _addr
    )
        view public
        returns(bytes)
    {
        return self.codeTrie[_addr];
    }

    function applyMessage(
        StateData storage self,
        VM storage _vm,
        uint256 _gas,
        address _to,
        address _sender,
        uint256 _value,
        bytes _data,
        bytes _code,
        uint256 _depth,
        address _createAddress,
        address _codeAddress,
        bool _shouldTransferValue,
        bool _isStatic
    )
        public
        returns(uint256, bytes)
    {

    }
}