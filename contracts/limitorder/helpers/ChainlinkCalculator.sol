 pragma solidity 0.8.10;
pragma abicoder v1;
  import "../interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
   contract ChainlinkCalculator {
    using SafeCast for int256;
     uint256 private constant _SPREAD_DENOMINATOR = 1e9;
    uint256 private constant _ORACLE_EXPIRATION_TIME = 30 minutes;
    uint256 private constant _INVERSE_MASK = 1 << 255;
        function singlePrice(AggregatorV3Interface oracle, uint256 inverseAndSpread, uint256 amount) external view returns(uint256) {
        (, int256 latestAnswer,, uint256 latestTimestamp,) = oracle.latestRoundData();
                 require(latestTimestamp + _ORACLE_EXPIRATION_TIME > block.timestamp, "CC: stale data");
        bool inverse = inverseAndSpread & _INVERSE_MASK > 0;
        uint256 spread = inverseAndSpread & (~_INVERSE_MASK);
        if (inverse) {
            return amount * spread * (10 ** oracle.decimals()) / latestAnswer.toUint256() / _SPREAD_DENOMINATOR;
        } else {
            return amount * spread * latestAnswer.toUint256() / (10 ** oracle.decimals()) / _SPREAD_DENOMINATOR;
        }
    }
        function doublePrice(AggregatorV3Interface oracle1, AggregatorV3Interface oracle2, uint256 spread, uint256 amount) external view returns(uint256) {
        require(oracle1.decimals() == oracle2.decimals(), "CC: oracle decimals don't match");
         (, int256 latestAnswer1,, uint256 latestTimestamp1,) = oracle1.latestRoundData();
        (, int256 latestAnswer2,, uint256 latestTimestamp2,) = oracle2.latestRoundData();
                 require(latestTimestamp1 + _ORACLE_EXPIRATION_TIME > block.timestamp, "CC: stale data O1");
                 require(latestTimestamp2 + _ORACLE_EXPIRATION_TIME > block.timestamp, "CC: stale data O2");
         return amount * spread * latestAnswer1.toUint256() / latestAnswer2.toUint256() / _SPREAD_DENOMINATOR;
    }
}