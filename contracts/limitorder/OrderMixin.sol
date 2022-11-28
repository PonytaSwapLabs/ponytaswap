pragma solidity 0.8.10;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./helpers/AmountCalculator.sol";
import "./helpers/ChainlinkCalculator.sol";
import "./helpers/NonceManager.sol";
import "./helpers/PredicateHelper.sol";
import "./interfaces/InteractiveNotificationReceiver.sol";
import "./libraries/ArgumentsDecoder.sol";
import "./libraries/Permitable.sol";

abstract contract OrderMixin is
    EIP712,
    AmountCalculator,
    ChainlinkCalculator,
    NonceManager,
    PredicateHelper,
    Permitable
{
    using Address for address;
    using ArgumentsDecoder for bytes;
    event OrderFilled(address indexed maker,bytes32 orderHash,uint256 remaining);
    event OrderCanceled(address indexed maker,bytes32 orderHash,uint256 remainingRaw);
    struct StaticOrder {
        uint256 salt;
        address makerAsset;
        address takerAsset;
        address maker;
        address receiver;
        address allowedSender;           
        uint256 makingAmount;
        uint256 takingAmount;
    }
    struct Order {
        uint256 salt;
        address makerAsset;
        address takerAsset;
        address maker;
        address receiver;
        address allowedSender;           
        uint256 makingAmount;
        uint256 takingAmount;
        bytes makerAssetData;
        bytes takerAssetData;
        bytes getMakerAmount;          
        bytes getTakerAmount;          
        bytes predicate;               
        bytes permit;                  
        bytes interaction;
    }
    bytes32 constant public LIMIT_ORDER_TYPEHASH = keccak256(
        "Order(uint256 salt,address makerAsset,address takerAsset,address maker,address receiver,address allowedSender,uint256 makingAmount,uint256 takingAmount,bytes makerAssetData,bytes takerAssetData,bytes getMakerAmount,bytes getTakerAmount,bytes predicate,bytes permit,bytes interaction)"
    );
    uint256 constant private _ORDER_DOES_NOT_EXIST = 0;
    uint256 constant private _ORDER_FILLED = 1;
    mapping(bytes32 => uint256) private _remaining;

    function remaining(bytes32 orderHash) external view returns(uint256) {
        uint256 amount = _remaining[orderHash];
        require(amount != _ORDER_DOES_NOT_EXIST, "LOP: Unknown order");
        unchecked { amount -= 1; }
        return amount;
    }

    function remainingRaw(bytes32 orderHash) external view returns(uint256) {
        return _remaining[orderHash];
    }

    function remainingsRaw(bytes32[] memory orderHashes) external view returns(uint256[] memory) {
        uint256[] memory results = new uint256[](orderHashes.length);
        for (uint256 i = 0; i < orderHashes.length; i++) {
            results[i] = _remaining[orderHashes[i]];
        }
        return results;
    }

    function simulateCalls(address[] calldata targets, bytes[] calldata data) external {
        require(targets.length == data.length, "LOP: array size mismatch");
        bytes memory reason = new bytes(targets.length);
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, bytes memory result) = targets[i].call(data[i]);
            if (success && result.length > 0) {
                success = result.length == 32 && result.decodeBool();
            }
            reason[i] = success ? bytes1("1") : bytes1("0");
        }
        revert(string(abi.encodePacked("CALL_RESULTS_", reason)));
    }

    function cancelOrder(Order memory order) external {
        require(order.maker == msg.sender, "LOP: Access denied");
        bytes32 orderHash = hashOrder(order);
        uint256 orderRemaining = _remaining[orderHash];
        require(orderRemaining != _ORDER_FILLED, "LOP: already filled");
        emit OrderCanceled(msg.sender, orderHash, orderRemaining);
        _remaining[orderHash] = _ORDER_FILLED;
    }

    function fillOrder(Order memory order,bytes calldata signature,uint256 makingAmount,uint256 takingAmount,uint256 thresholdAmount) external returns(uint256  , uint256  ) {
        return fillOrderTo(order, signature, makingAmount, takingAmount, thresholdAmount, msg.sender);
    }
    
    function fillOrderToWithPermit(Order memory order,bytes calldata signature,uint256 makingAmount,uint256 takingAmount,uint256 thresholdAmount,address target,bytes calldata permit) external returns(uint256  , uint256  ) {
        require(permit.length >= 20, "LOP: permit length too low");
        (address token, bytes calldata permitData) = permit.decodeTargetAndData();
        _permit(token, permitData);
        return fillOrderTo(order, signature, makingAmount, takingAmount, thresholdAmount, target);
    }
    
    function fillOrderTo(Order memory order,bytes calldata signature,uint256 makingAmount,uint256 takingAmount,uint256 thresholdAmount,address target) public returns(uint256  , uint256  ) {
        require(target != address(0), "LOP: zero target is forbidden");
        bytes32 orderHash = hashOrder(order);
        {   uint256 remainingMakerAmount = _remaining[orderHash];
            require(remainingMakerAmount != _ORDER_FILLED, "LOP: remaining amount is 0");
            require(order.allowedSender == address(0) || order.allowedSender == msg.sender, "LOP: private order");
            if (remainingMakerAmount == _ORDER_DOES_NOT_EXIST) {                                   require(SignatureChecker.isValidSignatureNow(order.maker, orderHash, signature), "LOP: bad signature");
                remainingMakerAmount = order.makingAmount;
                if (order.permit.length >= 20) {
                    (address token, bytes memory permit) = order.permit.decodeTargetAndCalldata();
                    _permitMemory(token, permit);
                    require(_remaining[orderHash] == _ORDER_DOES_NOT_EXIST, "LOP: reentrancy detected");
                }
            } else {
                unchecked { remainingMakerAmount -= 1; }
            }
                if (order.predicate.length > 0) {
                require(checkPredicate(order), "LOP: predicate returned false");
            }
                if ((takingAmount == 0) == (makingAmount == 0)) {
                revert("LOP: only one amount should be 0");
            } else if (takingAmount == 0) {
                uint256 requestedMakingAmount = makingAmount;
                if (makingAmount > remainingMakerAmount) {
                    makingAmount = remainingMakerAmount;
                }
                takingAmount = _callGetter(order.getTakerAmount, order.makingAmount, makingAmount, order.takingAmount);
                                                  require(takingAmount * requestedMakingAmount <= thresholdAmount * makingAmount, "LOP: taking amount too high");
            } else {
                uint256 requestedTakingAmount = takingAmount;
                makingAmount = _callGetter(order.getMakerAmount, order.takingAmount, takingAmount, order.makingAmount);
                if (makingAmount > remainingMakerAmount) {
                    makingAmount = remainingMakerAmount;
                    takingAmount = _callGetter(order.getTakerAmount, order.makingAmount, makingAmount, order.takingAmount);
                }
                                                  require(makingAmount * requestedTakingAmount >= thresholdAmount * takingAmount, "LOP: making amount too low");
            }
             require(makingAmount > 0 && takingAmount > 0, "LOP: can't swap 0 amount");
                          unchecked {
                remainingMakerAmount = remainingMakerAmount - makingAmount;
                _remaining[orderHash] = remainingMakerAmount + 1;
            }
            emit OrderFilled(msg.sender, orderHash, remainingMakerAmount);
        }
        _makeCall(
            order.takerAsset,
            abi.encodePacked(
                IERC20.transferFrom.selector,
                uint256(uint160(msg.sender)),
                uint256(uint160(order.receiver == address(0) ? order.maker : order.receiver)),
                takingAmount,
                order.takerAssetData
            )
        );
        if (order.interaction.length >= 20) {
            (address interactionTarget, bytes memory interactionData) = order.interaction.decodeTargetAndCalldata();
            InteractiveNotificationReceiver(interactionTarget).notifyFillOrder(
                msg.sender, order.makerAsset, order.takerAsset, makingAmount, takingAmount, interactionData
            );
        }
        _makeCall(
            order.makerAsset,
            abi.encodePacked(
                IERC20.transferFrom.selector,
                uint256(uint160(order.maker)),
                uint256(uint160(target)),
                makingAmount,
                order.makerAssetData
            )
        );
        return (makingAmount, takingAmount);
    }
    
    function checkPredicate(Order memory order) public view returns(bool) {
        bytes memory result = address(this).functionStaticCall(order.predicate, "LOP: predicate call failed");
        require(result.length == 32, "LOP: invalid predicate return");
        return result.decodeBool();
    }
    
    function hashOrder(Order memory order) public view returns(bytes32) {
        StaticOrder memory staticOrder;
        assembly {               staticOrder := order
        }
        return _hashTypedDataV4(
            keccak256(
                abi.encode(LIMIT_ORDER_TYPEHASH,staticOrder,keccak256(order.makerAssetData),keccak256(order.takerAssetData),keccak256(order.getMakerAmount),keccak256(order.getTakerAmount),keccak256(order.predicate),keccak256(order.permit),keccak256(order.interaction)
                )
            )
        );
    }
    
    function _makeCall(address asset, bytes memory assetData) private {
        bytes memory result = asset.functionCall(assetData, "LOP: asset.call failed");
        if (result.length > 0) {
            require(result.length == 32 && result.decodeBool(), "LOP: asset.call bad result");
        }
    }
    
    function _callGetter(bytes memory getter, uint256 orderExpectedAmount, uint256 amount, uint256 orderResultAmount) private view returns(uint256) {
        if (getter.length == 0) {
                         require(amount == orderExpectedAmount, "LOP: wrong amount");
            return orderResultAmount;
        } else {
            bytes memory result = address(this).functionStaticCall(abi.encodePacked(getter, amount), "LOP: getAmount call failed");
            require(result.length == 32, "LOP: invalid getAmount return");
            return result.decodeUint256();
        }
    }
}