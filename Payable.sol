pragma solidity ^0.8.0;

contract Payable {
    address public currentContextAddress;
    mapping(bytes32 => bool) transactionsExecuted;
    bytes32 EIP712_TRANSACTION_SCHEMA_HASH = keccak256(
    abi.encodePacked("Transaction(uint256 salt,uint256 expirationTimeSeconds,uint256 gasPrice,address signerAddress,bytes data)")
    );
    struct Transaction {
        uint256 salt;
        uint256 expirationTimeSeconds;
        uint256 gasPrice;
        address signerAddress;
        bytes fsignature;
    }

    function proceedTransactionForUser(
    Transaction memory transaction,
    bytes32 txHash,
    bytes memory signature) public returns(bool){
        require(_getAdressFromSignature(txHash, signature) == transaction.signerAddress, "Wrong address!");
        require(!transactionsExecuted[txHash], "Transaction already executed!");
        require(transaction.expirationTimeSeconds > block.timestamp, "Transaction expired!");
        _setCurrentContextAddressIfRequired(transaction.signerAddress);
        (bool success, bytes memory data) = address(this).delegatecall(transaction.fsignature);
        require(success, "Function call failed");
        transactionsExecuted[txHash] = true;
        return true;
    }
    
    function _setCurrentContextAddressIfRequired(address contextAddress) private {
        currentContextAddress = contextAddress;
    }

    function _getCurrentContextAddress() private view returns (address) {
        return currentContextAddress == address(0) ? msg.sender : currentContextAddress;
    }

    function _getAdressFromSignature(
    bytes32 txHash,
    bytes memory signature
    ) private pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return (address(0));
        }

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(txHash, v, r, s);
        }
    }
    
    function _getTransactionTypedHash(
    Transaction memory transaction
    ) private view returns (bytes32) {
        return keccak256(abi.encodePacked(
            EIP712_TRANSACTION_SCHEMA_HASH,
            transaction.salt,
            transaction.expirationTimeSeconds,
            transaction.gasPrice,
            uint256(uint160(transaction.signerAddress)),
            keccak256(transaction.fsignature)
        ));
    }

}