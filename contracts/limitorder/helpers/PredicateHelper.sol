 pragma solidity 0.8.10;
 import "@openzeppelin/contracts/utils/Address.sol";
   contract PredicateHelper {
    using Address for address;
        function or(address[] calldata targets, bytes[] calldata data) external view returns(bool) {
        require(targets.length == data.length, "PH: input array size mismatch");
        for (uint256 i = 0; i < targets.length; i++) {
            bytes memory result = targets[i].functionStaticCall(data[i], "PH: 'or' subcall failed");
            require(result.length == 32, "PH: invalid call result");
            if (abi.decode(result, (bool))) {
                return true;
            }
        }
        return false;
    }
        function and(address[] calldata targets, bytes[] calldata data) external view returns(bool) {
        require(targets.length == data.length, "PH: input array size mismatch");
        for (uint256 i = 0; i < targets.length; i++) {
            bytes memory result = targets[i].functionStaticCall(data[i], "PH: 'and' subcall failed");
            require(result.length == 32, "PH: invalid call result");
            if (!abi.decode(result, (bool))) {
                return false;
            }
        }
        return true;
    }
        function eq(uint256 value, address target, bytes memory data) external view returns(bool) {
        bytes memory result = target.functionStaticCall(data, "PH: eq");
        require(result.length == 32, "PH: invalid call result");
        return abi.decode(result, (uint256)) == value;
    }
        function lt(uint256 value, address target, bytes memory data) external view returns(bool) {
        bytes memory result = target.functionStaticCall(data, "PH: lt");
        require(result.length == 32, "PH: invalid call result");
        return abi.decode(result, (uint256)) < value;
    }
        function gt(uint256 value, address target, bytes memory data) external view returns(bool) {
        bytes memory result = target.functionStaticCall(data, "PH: gt");
        require(result.length == 32, "PH: invalid call result");
        return abi.decode(result, (uint256)) > value;
    }
        function timestampBelow(uint256 time) external view returns(bool) {
        return block.timestamp < time;       }
}