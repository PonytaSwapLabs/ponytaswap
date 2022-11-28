pragma solidity 0.8.10;
pragma abicoder v1;
  library ArgumentsDecoder {
    function decodeUint256(bytes memory data) internal pure returns(uint256) {
        uint256 value;
        assembly {              value := mload(add(data, 0x20))
        }
        return value;
    }
     function decodeBool(bytes memory data) internal pure returns(bool) {
        bool value;
        assembly {              value := eq(mload(add(data, 0x20)), 1)
        }
        return value;
    }
     function decodeTargetAndCalldata(bytes memory data) internal pure returns(address, bytes memory) {
        address target;bytes memory args;
        assembly {               target := mload(add(data, 0x14))
            args := add(data, 0x14)
            mstore(args, sub(mload(data), 0x14))
        }
        return (target, args);
    }
     function decodeTargetAndData(bytes calldata data) internal pure returns(address, bytes calldata) {
        address target;bytes calldata args;
        assembly {               target := shr(96, calldataload(data.offset))
        }
        args = data[20:];
        return (target, args);
    }
}