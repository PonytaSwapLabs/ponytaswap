 pragma solidity 0.8.10;
pragma abicoder v1;
 import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "./RevertReasonParser.sol";
import "../interfaces/IDaiLikePermit.sol";
  abstract contract Permitable {
    function _permit(address token, bytes calldata permit) internal {
        if (permit.length > 0) {
            bool success;
            bytes memory result;
            if (permit.length == 32 * 7) {
                (success, result) = token.call(abi.encodePacked(IERC20Permit.permit.selector, permit));
            } else if (permit.length == 32 * 8) {
                (success, result) = token.call(abi.encodePacked(IDaiLikePermit.permit.selector, permit));
            } else {
                revert("Wrong permit length");
            }
            if (!success) {
                revert(RevertReasonParser.parse(result, "Permit failed: "));
            }
        }
    }
     function _permitMemory(address token, bytes memory permit) internal {
        if (permit.length > 0) {
            bool success;
            bytes memory result;
            if (permit.length == 32 * 7) {
                                 (success, result) = token.call(abi.encodePacked(IERC20Permit.permit.selector, permit));
            } else if (permit.length == 32 * 8) {
                                 (success, result) = token.call(abi.encodePacked(IDaiLikePermit.permit.selector, permit));
            } else {
                revert("Wrong permit length");
            }
            if (!success) {
                revert(RevertReasonParser.parse(result, "Permit failed: "));
            }
        }
    }
}