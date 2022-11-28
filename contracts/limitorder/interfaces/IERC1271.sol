 pragma solidity ^0.8.0;
interface IERC1271 { 
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}
