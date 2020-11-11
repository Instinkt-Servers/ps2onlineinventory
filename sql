SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for Inventar
-- ----------------------------
DROP TABLE IF EXISTS `Inventar`;
CREATE TABLE `Inventar`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` char(25) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `steamid` bigint(20) NOT NULL,
  `item` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `menge` int(1) NOT NULL,
  `server` tinyint(4) NULL DEFAULT NULL,
  `desc` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `datum` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 92077 CHARACTER SET = latin1 COLLATE = latin1_swedish_ci ROW_FORMAT = Compact;

-- ----------------------------
-- Table structure for hashing
-- ----------------------------
DROP TABLE IF EXISTS `hashing`;
CREATE TABLE `hashing`  (
  `hash` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL,
  `steamid64` varchar(64) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL,
  `validation` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL
) ENGINE = InnoDB CHARACTER SET = latin1 COLLATE = latin1_swedish_ci ROW_FORMAT = Compact;

-- ----------------------------
-- Table structure for log
-- ----------------------------
DROP TABLE IF EXISTS `log`;
CREATE TABLE `log`  (
  `name` char(25) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `steamid` bigint(20) NOT NULL,
  `item` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `menge` int(11) NOT NULL,
  `datum` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB CHARACTER SET = latin1 COLLATE = latin1_swedish_ci ROW_FORMAT = Compact;

-- ----------------------------
-- Table structure for number
-- ----------------------------
DROP TABLE IF EXISTS `number`;
CREATE TABLE `number`  (
  `number` int(4) NULL DEFAULT NULL
) ENGINE = InnoDB CHARACTER SET = latin1 COLLATE = latin1_swedish_ci ROW_FORMAT = Compact;

SET FOREIGN_KEY_CHECKS = 1;
