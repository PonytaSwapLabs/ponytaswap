 pragma solidity 0.8.10;
pragma abicoder v1;
    library RevertReasonParser {
    bytes4 constant private _PANIC_SELECTOR = bytes4(keccak256("Panic(uint256)"));
    bytes4 constant private _ERROR_SELECTOR = bytes4(keccak256("Error(string)"));
     function parse(bytes memory data, string memory prefix) internal pure returns (string memory) {
        if (data.length >= 4) {
            bytes4 selector;
             assembly {                   selector := mload(add(data, 0x20))
            }
                if (selector == _ERROR_SELECTOR && data.length >= 68) {
                uint256 offset;
                bytes memory reason;
                assembly {                                            offset := mload(add(data, 36))
                    reason := add(data, add(36, offset))
                }
                require(data.length >= 36 + offset + reason.length, "Invalid revert reason");
                return string(abi.encodePacked(prefix, "Error(", reason, ")"));
            }
                else if (selector == _PANIC_SELECTOR && data.length == 36) {
                uint256 code;
                assembly {                                            code := mload(add(data, 36))
                }
                return string(abi.encodePacked(prefix, "Panic(", _toHex(code), ")"));
            }
        }
         return string(abi.encodePacked(prefix, "Unknown(", _toHex(data), ")"));
    }
     function _toHex(uint256 value) private pure returns(string memory) {
        return _toHex(abi.encodePacked(value));
    }
     function _toHex(bytes memory data) private pure returns(string memory) {
        bytes16 alphabet = 0x30313233343536373839616263646566;
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 * i + 2] = alphabet[uint8(data[i] >> 4)];
            str[2 * i + 3] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }
}