 pragma solidity 0.8.10;
pragma abicoder v1;
  interface InteractiveNotificationReceiver {
              function notifyFillOrder(address taker,address makerAsset,address takerAsset,uint256 makingAmount,uint256 takingAmount,bytes memory interactiveData) external;
}