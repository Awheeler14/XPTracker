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
-- Temporary view structure for view `game_recommendation_view`
--

DROP TABLE IF EXISTS `game_recommendation_view`;
/*!50001 DROP VIEW IF EXISTS `game_recommendation_view`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `game_recommendation_view` AS SELECT 
 1 AS `gameID`,
 1 AS `total_rating`,
 1 AS `rating_count`,
 1 AS `release_date`,
 1 AS `genre_vector`,
 1 AS `mode_vector`,
 1 AS `similar_gameIDs`*/;
SET character_set_client = @saved_cs_client;

--
-- Final view structure for view `game_recommendation_view`
--

/*!50001 DROP VIEW IF EXISTS `game_recommendation_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `game_recommendation_view` AS select `g`.`gameID` AS `gameID`,`g`.`total_rating` AS `total_rating`,`g`.`rating_count` AS `rating_count`,`g`.`release_date` AS `release_date`,`grv`.`genre_vector` AS `genre_vector`,`grv`.`mode_vector` AS `mode_vector`,group_concat(`gs`.`similar_gameID` order by `gs`.`similar_gameID` ASC separator ',') AS `similar_gameIDs` from ((`gme_games` `g` join `game_recommendation_vectors` `grv` on((`g`.`gameID` = `grv`.`game_id`))) left join `gme_similar_games` `gs` on((`g`.`gameID` = `gs`.`gameID`))) where (`g`.`total_rating` <> 0) group by `g`.`gameID`,`g`.`total_rating`,`g`.`rating_count`,`g`.`release_date`,`grv`.`genre_vector`,`grv`.`mode_vector` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Dumping events for database 'games_db'
--

--
-- Dumping routines for database 'games_db'
--
/*!50003 DROP FUNCTION IF EXISTS `LEVENSHTEIN` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `LEVENSHTEIN`(s1 VARCHAR(255), s2 VARCHAR(255)) RETURNS int
    DETERMINISTIC
BEGIN
    DECLARE s1_len, s2_len, i, j, c, c_temp, cost INT;
    DECLARE s1_char CHAR;
    DECLARE cv0, cv1 VARBINARY(256);

    SET s1_len = CHAR_LENGTH(s1), s2_len = CHAR_LENGTH(s2);
    SET cv1 = 0x00, j = 1, i = 1, c = 0;

    IF s1 = s2 THEN
        RETURN 0;
    ELSEIF s1_len = 0 THEN
        RETURN s2_len;
    ELSEIF s2_len = 0 THEN
        RETURN s1_len;
    ELSE
        -- Initialize the matrix for comparison
        WHILE j <= s2_len DO
            SET cv1 = CONCAT(cv1, UNHEX(HEX(j))), j = j + 1;
        END WHILE;

        -- Main Levenshtein calculation
        WHILE i <= s1_len DO
            SET s1_char = SUBSTRING(s1, i, 1), c = i, cv0 = UNHEX(HEX(i)), j = 1;
            WHILE j <= s2_len DO
                SET c = c + 1;
                IF s1_char = SUBSTRING(s2, j, 1) THEN
                    SET cost = 0;
                ELSE
                    SET cost = 1;
                END IF;

                -- Calculate minimum cost for edit operations
                SET c_temp = CONV(HEX(SUBSTRING(cv1, j, 1)), 16, 10) + cost;
                IF c > c_temp THEN SET c = c_temp; END IF;
                SET c_temp = CONV(HEX(SUBSTRING(cv1, j + 1, 1)), 16, 10) + 1;
                IF c > c_temp THEN SET c = c_temp; END IF;

                -- Update the matrix
                SET cv0 = CONCAT(cv0, UNHEX(HEX(c))), j = j + 1;
            END WHILE;

            SET cv1 = cv0, i = i + 1;
        END WHILE;
    END IF;

    RETURN c;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `LEVENSHTEIN_RATIO` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `LEVENSHTEIN_RATIO`(s1 VARCHAR(255), s2 VARCHAR(255)) RETURNS int
    DETERMINISTIC
BEGIN
    DECLARE s1_len, s2_len, max_len INT;
    SET s1_len = LENGTH(s1), s2_len = LENGTH(s2);
    IF s1_len > s2_len THEN SET max_len = s1_len; ELSE SET max_len = s2_len; END IF;
    RETURN ROUND((1 - LEVENSHTEIN(s1, s2) / max_len) * 100);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `AddToGameHistory` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `AddToGameHistory`(
    IN p_user INT, 
    IN p_game INT, 
    IN p_game_status INT, 
    OUT p_game_historyID INT
)
BEGIN
    DECLARE v_user_exists INT;
    DECLARE v_game_exists INT;
    DECLARE v_entry_exists INT;
    
    -- Validate the game status
    IF p_game_status NOT IN (0, 1, 2, 3) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid game status. Must be 0, 1, 2, or 3';
    END IF;

    -- Check if the user exists
    SELECT COUNT(*) INTO v_user_exists FROM usr_users WHERE userID = p_user;

    -- Check if the game exists
    SELECT COUNT(*) INTO v_game_exists FROM gme_games WHERE gameID = p_game;
    
    -- Check if this entry already exists 
    SELECT COUNT(*) INTO v_entry_exists FROM gme_game_history WHERE gameID = p_game AND userID = p_user;
    
    -- If either doesn't exist or the entry already exists, exit the procedure
    IF v_user_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User does not exist';
    END IF;

    IF v_game_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Game does not exist';
    END IF;
    
    IF v_entry_exists = 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Entry already exists';
    END IF;
    
    -- Insert new entry into game history
    INSERT INTO `games_db`.`gme_game_history` (`userID`, `gameID`, `status`)
    VALUES (p_user, p_game, p_game_status);

    -- Retrieve the newly inserted ID
    SET p_game_historyID = LAST_INSERT_ID();
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `CheckEmailExists` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `CheckEmailExists`(IN input_email VARCHAR(255), OUT email_exists BOOLEAN)
BEGIN
    -- Set the default value of email_exists to FALSE
    SET email_exists = FALSE;
    
    -- Check if the email already exists in the database
    IF EXISTS (SELECT 1 FROM usr_personal_data WHERE email = input_email) THEN
        SET email_exists = TRUE;  -- Set to TRUE if email is found
    END IF;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `CheckGameExistsInHistory` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `CheckGameExistsInHistory`(
    IN p_userID INT,
    IN p_gameID INT
)
BEGIN
    SELECT 
        *
    FROM `games_db`.`gme_game_history`
    WHERE `userID` = p_userID AND `gameID` = p_gameID;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `CheckUsernameExists` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `CheckUsernameExists`(IN input_username VARCHAR(20), OUT username_exists BOOLEAN)
BEGIN
    -- Set the default value of username_exists to FALSE
    SET username_exists = FALSE;
    
    -- Check if the username already exists in the database
    IF EXISTS (SELECT 1 FROM usr_users WHERE username = input_username) THEN
        SET username_exists = TRUE;  -- Set to TRUE if username is found
    END IF;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `DeleteGameHistoryEntry` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteGameHistoryEntry`(IN p_game_historyID INT)
BEGIN
    -- Delete the main game history entry (Cascade will take care of related entries)
    DELETE FROM `gme_game_history` WHERE `game_historyID` = p_game_historyID;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `FetchIGDBIDS` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `FetchIGDBIDS`()
BEGIN
	SELECT `gme_games`.`game_api_id`
	FROM `games_db`.`gme_games`;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetGameDetailsBatchJSON` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetGameDetailsBatchJSON`(IN game_ids_json JSON)
BEGIN
    -- select game info for IDs parsed from JSON array
    SELECT 
        g.gameID,
        g.game_name,
        g.cover_url,
        g.release_date
    FROM gme_games g
    WHERE JSON_CONTAINS(game_ids_json, CAST(g.gameID AS JSON), '$');
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetGameHistory` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetGameHistory`(IN p_game_historyID INT)
BEGIN
    SELECT 
        `gme_game_history`.`game_historyID`,
        `gme_game_history`.`gameID`,
        `gme_game_history`.`date_added`,
        `gme_game_history`.`date_start`,
        `gme_game_history`.`date_end`,
        `gme_game_history`.`rating`,
        `gme_game_history`.`time_played`,
        `gme_game_history`.`status`
    FROM 
        `games_db`.`gme_game_history`
    WHERE 
        `gme_game_history`.`game_historyID` = p_game_historyID;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetGameHistoryByID` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetGameHistoryByID`(IN p_game_historyID INT)
BEGIN
    SELECT 
        `gme_game_history`.`game_historyID`,
        `gme_game_history`.`gameID`,
        `gme_game_history`.`date_added`,
        `gme_game_history`.`date_start`,
        `gme_game_history`.`date_end`,
        `gme_game_history`.`rating`,
        `gme_game_history`.`time_played`,
        `gme_game_history`.`status`
    FROM 
        `games_db`.`gme_game_history`
    WHERE 
        `gme_game_history`.`game_historyID` = p_game_historyID;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetGameInfo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetGameInfo`(
    IN p_gameID INT
)
BEGIN
    SELECT 
        ANY_VALUE(g.game_name) AS game_name,
        ANY_VALUE(g.release_date) AS release_date,
        ANY_VALUE(g.total_rating) AS user_rating,
        ANY_VALUE(g.time_to_beat) AS time_to_beat,
        ANY_VALUE(g.cover_url) AS cover_url,
        ANY_VALUE(d.description) AS description,
        GROUP_CONCAT(DISTINCT CONCAT(c.company_name, ' (', c.logo_url, ')') ORDER BY c.company_name SEPARATOR ', ') AS companies_with_logos,
        GROUP_CONCAT(DISTINCT gen.genre_name ORDER BY gen.genre_name SEPARATOR ', ') AS genres,
        ANY_VALUE(CONCAT(ar.rating_system, ' ', ar.rating)) AS age_rating,
        GROUP_CONCAT(DISTINCT gm.game_mode_name ORDER BY gm.game_mode_name SEPARATOR ', ') AS game_mode,
        
        -- Subquery for Similar Games
        (SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'gameID', g_sim.gameID,
                'game_name', g_sim.game_name,
                'release_date', g_sim.release_date,
                'cover_url', g_sim.cover_url
            )
        ) 
        FROM games_db.gme_similar_games sg
        LEFT JOIN games_db.gme_games g_sim 
            ON sg.similar_gameID = g_sim.game_api_id
        WHERE sg.gameID = g.gameID) AS similar_games
        
    FROM games_db.gme_games g
    LEFT JOIN games_db.gme_game_descriptions d 
        ON g.gameID = d.gameID
    LEFT JOIN games_db.gme_company_game_relationships cg 
        ON g.gameID = cg.gameID
    LEFT JOIN games_db.gme_companies c 
        ON cg.companyID = c.companyID
    LEFT JOIN games_db.gme_game_genre_relationships gg 
        ON g.gameID = gg.gameID
    LEFT JOIN games_db.gme_genres gen 
        ON gg.genreID = gen.genreID
    LEFT JOIN games_db.gme_game_age_ratings gar 
        ON g.gameID = gar.gameID
    LEFT JOIN games_db.gme_age_ratings ar 
        ON gar.age_ratingID = ar.age_ratingID
    LEFT JOIN games_db.gme_game_game_modes ggm
        ON g.gameID = ggm.gameID
    LEFT JOIN games_db.gme_game_modes gm
        ON ggm.game_modeID = gm.game_modeID
    WHERE g.gameID = p_gameID
    GROUP BY g.gameID;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetGameSuggestions` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetGameSuggestions`(IN p_user INT, IN p_recent BOOL)
BEGIN
    SELECT *
    FROM game_recommendation_view
    WHERE total_rating >= 70
      AND rating_count > 40
      AND LENGTH(REPLACE(genre_vector, '0', '')) >= 1
      AND LENGTH(REPLACE(mode_vector, '0', '')) >= 1
      AND gameID NOT IN (
        SELECT gameID FROM gme_game_history WHERE userID = p_user
      )
      AND (
          (p_recent = TRUE AND release_date >= CURDATE() - INTERVAL 9 MONTH)
          OR
          (p_recent = FALSE 
           AND release_date < CURDATE() - INTERVAL 9 MONTH 
           AND release_date >= CURDATE() - INTERVAL 144 MONTH)
      )
    LIMIT 20000;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetNote` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetNote`(IN history_id INT)
BEGIN
    -- Check if a note exists for the provided game_historyID
    DECLARE note_exists INT DEFAULT 0;

    -- Check if the note already exists
    SELECT COUNT(*) INTO note_exists
    FROM `games_db`.`gme_notes`
    WHERE `game_historyID` = history_id;

    -- If no note exists, insert a new entry
    IF note_exists = 0 THEN
        INSERT INTO `games_db`.`gme_notes` (`game_historyID`, `note`)
        VALUES (history_id, '');  -- Empty string 
    END IF;

    -- Select the note for the provided game_historyID
    SELECT `notesID`, `game_historyID`, `note`, `last_updated`
    FROM `games_db`.`gme_notes`
    WHERE `game_historyID` = history_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetNoteByGameHistoryID` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetNoteByGameHistoryID`(IN history_id INT)
BEGIN
    SELECT `notesID`, `game_historyID`, `note`, `last_updated`
    FROM `games_db`.`gme_notes`
    WHERE `game_historyID` = history_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetPassword` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetPassword`(IN p_userID INT, OUT hashed_password VARCHAR(200))
BEGIN
    -- Join usr_users and usr_personal_data tables to get the hashed password based on username
    SELECT p.password
    INTO hashed_password
    FROM games_db.usr_users u
    INNER JOIN games_db.usr_personal_data p ON u.userID = p.userID
    WHERE u.userID = p_userID
    LIMIT 1;
    
    -- Debugging output
    SELECT hashed_password AS debug_output;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetUpdatedHistory` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetUpdatedHistory`(IN p_game_historyID INT)
BEGIN
    SELECT 
        `date_start`,
        `date_end`,
        `rating`,
        `time_played`,
        `status`
    FROM `games_db`.`gme_game_history`
    WHERE `game_historyID` = p_game_historyID;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetUser` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetUser`(IN p_userID INT)
BEGIN
   SELECT 
      `username`,
      `profile_picture`
   FROM `games_db`.`usr_users`
   WHERE `userID` = p_userID
   LIMIT 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetUserGameHistory` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetUserGameHistory`(IN p_userID INT)
BEGIN
    SELECT h.game_historyID,
           h.gameID,
           g.game_name,
           g.cover_url,
           g.release_date,
           GROUP_CONCAT(ge.genre_name ORDER BY ge.genre_name SEPARATOR ', ') AS genres,
           h.rating,
           h.status,
           h.date_added,
           h.date_start,
           h.date_end,
           time_played,
           h.last_updated,
           g.time_to_beat
    FROM gme_game_history AS h
    LEFT JOIN gme_games AS g ON h.gameID = g.gameID
    LEFT JOIN gme_game_genre_relationships AS gg ON g.gameID = gg.gameID
    LEFT JOIN gme_genres AS ge ON gg.genreID = ge.genreID
    WHERE h.userID = p_userID
    GROUP BY h.game_historyID, h.gameID, g.game_name, g.cover_url, g.release_date, h.rating, h.status;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetUserID` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetUserID`(IN username VARCHAR(20), OUT p_user_id  int)
BEGIN
   -- Join usr_users and usr_personal_data tables to get the userID based on username
    SELECT p.userID
    INTO p_user_id
    FROM games_db.usr_users u
    INNER JOIN games_db.usr_personal_data p ON u.userID = p.userID
    WHERE u.username = username
    LIMIT 1;
    
    -- Debugging output
    SELECT p_user_id AS debug_output;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetUserVectors` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetUserVectors`(IN p_user INT)
BEGIN
	SELECT RV.*,
    GH.rating
	FROM `game_recommendation_view` AS RV
	INNER JOIN `gme_game_history` AS GH ON RV.gameID = GH.gameID
	WHERE GH.userID = p_user;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `get_user_vectors` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_user_vectors`(IN p_user INT)
BEGIN
	SELECT RV.*
	FROM `game_recommendation_view` AS RV
	INNER JOIN `gme_game_history` AS GH ON RV.gameID = GH.gameID
	WHERE GH.userID = p_user;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `InsertAgeRatingAndRelationship` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertAgeRatingAndRelationship`(
    IN p_rating varchar(50),
    IN p_rating_system varchar(50),
    IN p_gameID INT
)
BEGIN
    DECLARE v_age_ratingID varchar(50);
    DECLARE v_count varchar(50);

    -- Check if age rating exists based on rating and rating system
    SELECT age_ratingID INTO v_age_ratingID
    FROM gme_age_ratings
    WHERE rating = p_rating AND rating_system = p_rating_system;

    IF v_age_ratingID IS NULL THEN
        -- Insert age rating if it doesn't exist
        INSERT INTO gme_age_ratings (rating, rating_system)
        VALUES (p_rating, p_rating_system);
        SET v_age_ratingID = LAST_INSERT_ID();
    END IF;

    -- Check if relationship already exists
    SELECT COUNT(*) INTO v_count
    FROM gme_game_age_ratings
    WHERE gameID = p_gameID AND age_ratingID = v_age_ratingID;

    IF v_count = 0 THEN
        -- Insert into relationship table
        INSERT INTO gme_game_age_ratings (gameID, age_ratingID)
        VALUES (p_gameID, v_age_ratingID);
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `InsertCompanyAndRelationship` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertCompanyAndRelationship`(
	IN p_company_api_id INT,
    IN p_company_name VARCHAR(200),
    IN p_company_logo_url VARCHAR (512),
    IN p_gameID INT
)
BEGIN 
	DECLARE v_companyID INT;
    DECLARE v_count INT;
    
     -- Check if company exists
    SELECT companyID INTO v_companyID
    FROM gme_companies
    WHERE company_name = p_company_name;
    
    IF v_companyID IS NULL THEN
		-- insert company if doesnt exist
        INSERT INTO `games_db`.`gme_companies` (`company_api_id`, `company_name`,`logo_url`)
		VALUES (p_company_api_id, p_company_name, p_company_logo_url);
        SET v_companyID = LAST_INSERT_ID();
	END IF;
    
    -- insert into relationship table 
    SELECT COUNT(*) INTO v_count
    FROM `gme_company_game_relationships`
    WHERE `companyID` = v_companyID AND `gameID` = p_gameID;
    
    IF v_count = 0 THEN 
		INSERT INTO `games_db`.`gme_company_game_relationships`(`companyID`,`gameID`)
		VALUES
		(v_companyID,p_gameID);
	END IF;



END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `InsertGameModeAndRelationship` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertGameModeAndRelationship`(
    IN p_game_mode_api_id INT,
    IN p_game_mode_name VARCHAR(255),
    IN p_gameID INT
)
BEGIN
    DECLARE v_game_modeID INT;
    DECLARE v_count INT;

    -- Check if game mode exists
    SELECT game_modeID INTO v_game_modeID
    FROM gme_game_modes
    WHERE game_mode_api_id = p_game_mode_api_id;

    IF v_game_modeID IS NULL THEN
        -- Insert game mode if it doesn't exist
        INSERT INTO gme_game_modes (game_mode_api_id, game_mode_name)
        VALUES (p_game_mode_api_id, p_game_mode_name);
        SET v_game_modeID = LAST_INSERT_ID();
    END IF;

    -- Check if relationship already exists
    SELECT COUNT(*) INTO v_count
    FROM gme_game_game_modes
    WHERE gameID = p_gameID AND game_modeID = v_game_modeID;

    IF v_count = 0 THEN
        -- Insert into relationship table
        INSERT INTO gme_game_game_modes (gameID, game_modeID)
        VALUES (p_gameID, v_game_modeID);
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `InsertGenreAndRelationship` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertGenreAndRelationship`(
	IN p_genre_api_id INT,
    IN p_genre_name VARCHAR(200),
    IN p_gameID INT
)
BEGIN
	DECLARE v_genreID INT;
    DECLARE v_count INT;
    
    -- Check if genre exists
    SELECT genreID INTO v_genreID
    FROM gme_genres
    WHERE genre_name = p_genre_name;
    
    IF v_genreID IS NULL THEN
		-- Insert genre if it doesnt exists
        INSERT INTO `games_db`.`gme_genres`(`genre_api_id`,`genre_name`)
		VALUES (p_genre_api_id, p_genre_name);
        SET v_genreID = LAST_INSERT_ID();
	END IF;
    
    -- insert into 
    SELECT COUNT(*) INTO v_count
    FROM `gme_game_genre_relationships`
    WHERE `genreID` = v_genreID AND `gameID` = p_gameID;
    
    IF v_count = 0 THEN 
		INSERT INTO `games_db`.`gme_game_genre_relationships`(`genreID`,`gameID`)
		VALUES
		(v_genreID,p_gameID);
	END IF;
	
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `InsertKeywordAndRelationship` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertKeywordAndRelationship`(
    IN p_keyword_api_id INT,
    IN p_keyword_name VARCHAR(255),
    IN p_gameID INT
)
BEGIN
    DECLARE v_keywordID INT;
    DECLARE v_count INT;

    -- Check if keyword exists by name or api_id
    SELECT keywordID INTO v_keywordID
    FROM gme_keywords
    WHERE keyword_api_id = p_keyword_api_id OR keyword = p_keyword_name;

    IF v_keywordID IS NULL THEN
        -- Insert keyword if it doesn't exist
        INSERT INTO gme_keywords (keyword_api_id, keyword)
        VALUES (p_keyword_api_id, p_keyword_name);
        SET v_keywordID = LAST_INSERT_ID();
    END IF;

    -- Check if relationship already exists
    SELECT COUNT(*) INTO v_count
    FROM gme_game_keywords
    WHERE gameID = p_gameID AND keywordID = v_keywordID;

    IF v_count = 0 THEN
        -- Insert into relationship table
        INSERT INTO gme_game_keywords (gameID, keywordID)
        VALUES (p_gameID, v_keywordID);
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `InsertOrUpdateGame` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertOrUpdateGame`(
    IN p_game_api_id INT,
    IN p_game_name VARCHAR(250),
    IN p_release_date DATE,
    IN p_user_rating FLOAT,
    IN p_time_to_beat FLOAT,
    IN p_cover_url VARCHAR(512),
    IN p_description TEXT,
    IN p_similar_games JSON, -- Expecting JSON array of IGDB API IDs
    OUT p_return_gameID INT
)
BEGIN
    DECLARE v_gameID INT;
    DECLARE v_descriptionID INT;
    DECLARE v_similar_game_api_id INT;
    DECLARE v_count INT;
    DECLARE i INT DEFAULT 0;
    DECLARE json_length INT;
    
    -- Check if the game is in the database
    SELECT gameID INTO v_gameID
    FROM gme_games
    WHERE game_api_id = p_game_api_id;
    
    IF v_gameID IS NULL THEN
        -- Insert the game if it doesn't exist
        INSERT INTO `games_db`.`gme_games` (`game_api_id`, `game_name`, `release_date`, `total_rating`, `time_to_beat`, `cover_url`)
        VALUES (p_game_api_id, p_game_name, p_release_date, p_user_rating, p_time_to_beat, p_cover_url);
        SET v_gameID = LAST_INSERT_ID();
    ELSE 
        -- Update game if it exists 
        UPDATE `games_db`.`gme_games` 
        SET `game_name` = p_game_name, `release_date` = p_release_date, 
        `total_rating` = p_user_rating, `time_to_beat` = p_time_to_beat, `cover_url` = p_cover_url 
        WHERE `gameID` = v_gameID;
    END IF;
    
    -- Check if description is in database
    SELECT descriptionID INTO v_descriptionID
    FROM gme_game_descriptions 
    WHERE gameID = v_gameID;
    
    IF v_descriptionID IS NULL THEN 
        -- Insert description if it does not exist 
        INSERT INTO `games_db`.`gme_game_descriptions` (`gameID`, `description`)
        VALUES (v_gameID, p_description);
    ELSE 
        -- Update description if it exists
        UPDATE `games_db`.`gme_game_descriptions`
        SET `description` = p_description
        WHERE `gameID` = v_gameID;
    END IF;
    
    -- Handle similar games (only store IGDB API IDs)
    SET json_length = JSON_LENGTH(p_similar_games);
    
    WHILE i < json_length DO
        -- Extract similar game API ID from JSON
        SET v_similar_game_api_id = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_similar_games, CONCAT('$[', i, ']'))) AS UNSIGNED);

        -- Check if the relationship already exists
        SELECT COUNT(*) INTO v_count
        FROM gme_similar_games
        WHERE gameID = v_gameID AND similar_gameID = v_similar_game_api_id;

        -- Insert the relationship if it doesn't exist
        IF v_count = 0 THEN
            INSERT INTO gme_similar_games (gameID, similar_gameID) 
            VALUES (v_gameID, v_similar_game_api_id);
        END IF;
        
        SET i = i + 1;
    END WHILE;

    -- Return the inserted/updated gameID
    SET p_return_gameID = v_gameID;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `InsertUserInformation` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertUserInformation`(IN email VARCHAR(255), IN username VARCHAR(20), IN paswd VARCHAR(200), IN profile_pic VARCHAR(200))
BEGIN

	DECLARE v_userID INT;
	
    INSERT INTO `games_db`.`usr_users`(`username`,`profile_picture`)
	VALUES(username,profile_pic);
	SET v_userID = LAST_INSERT_ID();
    
    INSERT INTO `games_db`.`usr_personal_data`(`userID`,`email`,`password`)
	VALUES(v_userID,email,paswd);

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `SearchGamesByTitle` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `SearchGamesByTitle`(IN search_title VARCHAR(255))
BEGIN
    SELECT 
        gameID,
        game_name,
        release_date,
        cover_url
    FROM (
        SELECT *
        FROM gme_games
        WHERE MATCH(game_name) AGAINST (search_title IN NATURAL LANGUAGE MODE)
        LIMIT 100
    ) AS filtered_matches
    WHERE LEVENSHTEIN_RATIO(game_name, search_title) > 35
    AND total_rating > 0
    ORDER BY LEVENSHTEIN_RATIO(game_name, search_title) DESC
    LIMIT 5;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `search_games_by_title` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `search_games_by_title`(IN search_title VARCHAR(255))
BEGIN
    SELECT 
        gameID,
        game_name,
        release_date,
        cover_url
    FROM (
        SELECT *
        FROM gme_games
        WHERE MATCH(game_name) AGAINST (search_title IN NATURAL LANGUAGE MODE)
        LIMIT 100
    ) AS filtered_matches
    WHERE LEVENSHTEIN_RATIO(game_name, search_title) > 35
    AND total_rating > 0
    ORDER BY LEVENSHTEIN_RATIO(game_name, search_title) DESC
    LIMIT 5;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `UpdateGameEndDate` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateGameEndDate`(p_game_historyID INT, p_end_date DATE)
BEGIN
    UPDATE `games_db`.`gme_game_history`
	SET
	`date_end` = p_end_date
	WHERE `game_historyID` = p_game_historyID;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `UpdateGameRating` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateGameRating`(p_game_historyID INT, p_rating INT)
BEGIN
    -- Ensure the rating is valid (1-10) or 0 (to set NULL)
    IF p_rating NOT IN (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid game rating. Must be 0 (for null) or between 1 and 10';
    END IF;

    -- Update the rating, setting it to NULL if 0 is passed
    UPDATE `games_db`.`gme_game_history`
    SET `rating` = IF(p_rating = 0, NULL, CAST(p_rating AS CHAR))
    WHERE `game_historyID` = p_game_historyID;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `UpdateGameStartDate` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateGameStartDate`(p_game_historyID INT, p_start_date DATE)
BEGIN
    UPDATE `games_db`.`gme_game_history`
	SET
	`date_start` = p_start_date
	WHERE `game_historyID` = p_game_historyID;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `UpdateGameStatus` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateGameStatus`(IN p_game_historyID INT, IN p_game_status INT)
BEGIN
    DECLARE v_game_history_exists INT;
    
    IF p_game_status NOT IN (0, 1, 2, 3) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid game status. Must be 0, 1, 2, or 3';
    END IF;

    -- Check if the entry exists
    SELECT COUNT(*) INTO v_game_history_exists FROM gme_game_history WHERE game_historyID = p_game_historyID;

    -- If doesn't exist, exit the procedure
    IF v_game_history_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Game History entry does not exist';
    END IF;
    
    UPDATE `games_db`.`gme_game_history`
	SET
	`status` = p_game_status
	WHERE `game_historyID` = p_game_historyID;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `UpdatePassword` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdatePassword`(IN p_userID INT, IN p_new_password VARCHAR(200))
BEGIN
    -- Join usr_users and usr_personal_data tables to get the hashed password based on username
    UPDATE `games_db`.`usr_personal_data`
	SET
	`password` = p_new_password
	WHERE `userID` = p_userID;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `UpdateProfilePic` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateProfilePic`(IN p_username VARCHAR(20), IN p_profile_path VARCHAR(200))
BEGIN
	DECLARE v_userID INT;
    
    SELECT userID INTO v_userID
    FROM usr_users
    WHERE username = p_username;
    
    IF v_userID IS NOT NULL THEN
		UPDATE `games_db`.`usr_users`
		SET
		`profile_picture` = p_profile_path
		WHERE `userID` = v_userID;
	END IF;
	
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `UpdateTimePlayed` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateTimePlayed`(p_game_historyID INT,  p_time_to_add INT)
BEGIN
    UPDATE `games_db`.`gme_game_history`
	SET
	`time_played` = `time_played` + p_time_to_add
	WHERE `game_historyID` = p_game_historyID;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-05-04 18:17:01
