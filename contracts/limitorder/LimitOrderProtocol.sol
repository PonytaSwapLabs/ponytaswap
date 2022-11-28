 
pragma solidity 0.8.10;
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./OrderMixin.sol";
contract LimitOrderProtocol is
    EIP712("Ponyta Limit Order Protocol", "1"),
    OrderMixin
{
    function DOMAIN_SEPARATOR() external view returns(bytes32) {
        return _domainSeparatorV4();
    }
}