-- MySQL dump 10.13  Distrib 8.0.32, for Win64 (x86_64)
--
-- Host: localhost    Database: games_db
-- ------------------------------------------------------
-- Server version	8.0.32

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `gme_game_history`
--

DROP TABLE IF EXISTS `gme_game_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `gme_game_history` (
  `game_historyID` int NOT NULL AUTO_INCREMENT,
  `userID` int NOT NULL,
  `gameID` int NOT NULL,
  `date_added` date NOT NULL DEFAULT (curdate()),
  `date_start` date DEFAULT NULL,
  `date_end` date DEFAULT NULL,
  `rating` tinyint unsigned DEFAULT NULL,
  `time_played` int DEFAULT '0' COMMENT 'INT stored in seconds for time played (will give up to 136 years so think im good), will conver to hours, minutes for output/input',
  `status` tinyint unsigned NOT NULL DEFAULT '0',
  `last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`game_historyID`),
  KEY `FK_history_users_idx` (`userID`),
  KEY `FK_history_games_idx` (`gameID`),
  CONSTRAINT `FK_history_games` FOREIGN KEY (`gameID`) REFERENCES `gme_games` (`gameID`),
  CONSTRAINT `FK_history_users` FOREIGN KEY (`userID`) REFERENCES `usr_users` (`userID`),
  CONSTRAINT `chk_rating_range` CHECK (((`rating` is null) or (`rating` between 1 and 10)))
) ENGINE=InnoDB AUTO_INCREMENT=132 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='current status of each game a user is playing\nstatus: \n0 = want to play\n1 = playing\n2 = completed\n3 = dropped';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-05-04 18:17:00
