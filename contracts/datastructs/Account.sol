pragma solidity ^0.4.24;

library Account {

    bytes32 constant EMPTY_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    struct AccountState {
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    function addNonce(AccountState accountState) internal pure {
        accountState.nonce++;
    }

    function addBalance(AccountState accountState, uint256 balance)
        internal
        pure
    {
        accountState.balance += balance;
    }

    function hasBalance(AccountState accountState, uint256 balance) 
        internal
        pure
        returns(bool)
    {
        return (accountState.balance >= balance);
    }

    function hasCode(AccountState accountState) internal pure returns(bool) {
        return (accountState.codeHash ^ EMPTY_HASH != 0);
    }

    function toBytes(AccountState accountState) internal pure returns(bytes) {
        return abi.encode(
            accountState.nonce,
            accountState.balance,
            accountState.storageRoot,
            accountState.codeHash
        );
    }

}