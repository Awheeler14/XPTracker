from database import DatabaseConnection
from api import TwitchAuthenticator
from api import IGDBAPI
from api import GameDataParser
import json


# This file is way too big, I should have seperate the classes further, I just didnt expect to need so much functionality and dont
# want to mess with the structure now 

class GameDataHandler():
    """
    A class to handle inputting Game data from the my sql database.

    Attributes:
        db(DatabaseConnection): connection to the database
        igdb_api(IGDBAPI): handles connection to the api

    Methods:
        EnterGameData(title): Insert the parsed game data into the database.
    """

    def __init__(self, client_id, client_secret, host, user, password, database = "games_db"):
        """

        Initialize the EnterData class with the provided data.

        """
        # Create an instance of DatabaseConnection
        self.db = DatabaseConnection(host, user, password, database)


        # Create an instance of IGDBAPI using the TwitchAuthenticator class
        self.igdb_api = IGDBAPI(client_id, TwitchAuthenticator(client_id, client_secret))

        self.processed_count = 0
        self.batch_size = 100  # Save progress after every 100 entries

    def EnterGameData(self,title):
        """
        Handles request and entering data (old)
        """

        # Make the request to IGDB API
        game_data = self.igdb_api.search_by_title(title)

        # Check if the response contains results
        if game_data:
            top_game = game_data[0]

            # Initialize the parser and parse the game data
            parsed = GameDataParser(top_game, self.igdb_api)

            # Connect to the database
            with self.db.connection_handler() as conn:
                with conn.cursor() as cursor:

                    # Insert/Update the game data
                    game_db_id = cursor.callproc('InsertOrUpdateGame', (parsed.game_id, parsed.game_name, parsed.release_date, parsed.user_rating, parsed.time_to_beat, parsed.cover_url, parsed.summary,0))

                    # Insert the genres and relationship with game

                    for genre in parsed.genres:
                        cursor.callproc('InsertGenreAndRelationship', (genre['id'], genre['name'], game_db_id[-1]))

                    # Insert the companies and relationship with game

                    for company in parsed.involved_companies:
                        cursor.callproc('InsertCompanyAndRelationship', (company['id'], company['name'], company['logo_url'], game_db_id[-1]))


                    conn.commit()
                    
            print("Returned Game ID:", game_db_id[-1])

        else:
            print(f"No game found with title: {title}")
    
    def EnterParsedData(self, parsed):
        """
        Insert the parsed game data into the database.
        """
        from database.populate_database import save_progress

        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                # Insert/Update game data in DB
                game_db_id = cursor.callproc('InsertOrUpdateGame', (
                    parsed.game_id, parsed.game_name, parsed.release_date, parsed.user_rating,
                    parsed.time_to_beat, parsed.cover_url, parsed.summary, json.dumps(parsed.similar_games), 0
                ))

                # Insert genres and relationship with game
                for genre in parsed.genres:
                    cursor.callproc('InsertGenreAndRelationship', (genre['id'], genre['name'], game_db_id[-1]))

                # Insert companies and relationship with game
                for company in parsed.involved_companies:
                    cursor.callproc('InsertCompanyAndRelationship', (
                        company['id'], company['name'], company['logo_url'], game_db_id[-1]
                    ))

                # Insert Keywords and relationships with game
                for keyword in parsed.keywords:
                    cursor.callproc('InsertKeywordAndRelationship', (keyword['id'], keyword['name'], game_db_id[-1]))

                # Insert Game Modes and relationships with game
                for game_mode in parsed.game_modes:
                    cursor.callproc('InsertGameModeAndRelationship', (game_mode['id'], game_mode['name'], game_db_id[-1]))

                # Insert Age Ratings and relationships with game
                for age_rating in parsed.age_ratings:
                    cursor.callproc('InsertAgeRatingAndRelationship', (age_rating['rating'], age_rating['organization'], game_db_id[-1]))

                conn.commit()

        # Increment the processed count
        self.processed_count += 1

        # Save progress every self.batch_size games
        if self.processed_count == self.batch_size:
            print(f"Saving progress after {self.processed_count} games...")
            save_progress(parsed.game_id)  # Save progress after processing this game

            # Reset processed count after saving progress
            self.processed_count = 0
        else:
            print(f"Game data inserted for {parsed.game_id} with ID: {parsed.game_id}")

    # Ideally this needs to be part of Enter Parsed data but having to do it as its own thing because I didnt get it in orignal population. 
    # Would fix if had more time, but this is honsestly fine for the current database and Im time limited
    def EnterRatingCount(self,rating_count_array):
        """
        bulk insert Rating count for all games 
        """
        # Trying out bulk queries
        query = '''
            UPDATE gme_games
            SET rating_count = %s
            WHERE game_api_id = %s
        '''

        formatted_data = [(rating_count, game_id) for game_id, rating_count in rating_count_array]

        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                cursor.executemany(query, formatted_data)
            conn.commit()

    def GetAllGameIDSAPI(self):
        """
        fetch all IGDB API IDs in database (for modifying existing entries)
        """
        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                cursor.callproc('FetchIGDBIDS')
                for result in cursor.stored_results():
                    return [row[0] for row in result.fetchall()]
                

class UserDataHandler:
    """
    A class to handle retrieving and entering user data with the mysql database

    Attributes:
        db(DatabaseConnection): connection to the database

    Methods:
        check_email_exists(email:check if email exists in the datbase
    """
    def __init__(self, host, user, password, database = "games_db"):

        self.db = DatabaseConnection(host, user, password, database)

    def get_user_id(self,username):
        """
        gets user id from database 
        """

        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                    results = cursor.callproc('GetUserID', (username,0))
                    user_id = results[-1]

        return user_id
                    

    def check_email_exists(self,email):
        """
        Checks if email already exists in the database

        Args:
            email(str): the email to check 

        Returns:
            email_exists: bool based on if email exists or not
        """
         
        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                results = cursor.callproc('CheckEmailExists',(email,0))
                email_exists = results[-1]

        return email_exists
    
    def check_username_exists(self,username):
        """
        Checks if username already exists in the database

        Args:
            username(str): the username to check 

        Returns:
            username_exists: bool based on if email exists or not
        """

        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                results = cursor.callproc('CheckUsernameExists',(username,0))
                username_exists = results[-1]

        return username_exists

    def insert_user_data(self,email,username,hashed_password):
        """
        Inserts user information into the database

        Args:
            email(str): users email
            username(str): users username
            hashed_password(bytes): users password
            profile_pic(str): users profile picture
        """

        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                cursor.callproc('InsertUserInformation',(email,username,hashed_password,None))

                conn.commit()

    def insert_profile_pic_path(self,username,path):
        """
         Inserts path to uploaded profile picture into the database

         Args:
            username(str): users username 
            path(str): path to the picture to be stored
        """

        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                cursor.callproc('UpdateProfilePic',(username,path))

                conn.commit()

    def check_passwords_match(self,user_id):
        """
        Makes sure the passwords match when a user inputs a password

        Args:
            user_id(int): the users id

        Return:
            the stored hashed password
        """

        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                    results = cursor.callproc('GetPassword', (user_id,0))
                    hashed_password = results[-1]
                    
        return hashed_password
    
    def update_password(self, user_id,new_password):
        """
        Updates users password to new password in database 

        Args:
            user_id(str): the users id
            new_password(bytes): users new password 
        """

        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                cursor.callproc('UpdatePassword',(user_id,new_password))

                conn.commit()

    def get_user_information(self,user_id):
        """
        Retrieves username and profile pic currently (will also get friends later)

        Args:
            user_id(str): the users id

        Returns:
            username and profile pic path 
        """

        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                # Call the stored procedure with the user_id
                cursor.callproc('GetUser', (user_id,))

                # Fetch the result
                for result in cursor.stored_results():
                    # Assuming that the stored procedure returns (username, profile_picture)
                    for row in result.fetchall():
                        username, profile_picture = row
                        return username, profile_picture  # Return both the username and profile_picture

        return None  # Return None if no result is found
        

class UserGamesHandler:
    """
    A class to handle users adding games to their 'log'
    """
    def __init__(self,host, user, password, database = "games_db"):

        self.db = DatabaseConnection(host, user, password, database)


    def add_game_to_list(self, user_id, game_id, status):
        """
        Adds a game to the user's log and returns the new game_historyID.

        Args:
            user_id (int): The user's ID.
            game_id (int): The game's ID.
            status (int): The status of the game in the log.

        Returns:
            int: The newly created game_historyID, or None if an error occurs.
        """
        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                print(status)
                
                results = cursor.callproc('AddToGameHistory', (user_id, game_id, status,0))
                id = results[-1]
               
                conn.commit()
        return id
            
          

    def update_status(self,game_history_id,status):
        """
        updates status of game in log

        Args:
            game_history_id(int): id of the entry to update
            status(int): status of the game in the log 
        """

        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                cursor.callproc('UpdateGameStatus',(game_history_id,status))

                conn.commit()

    def update_rating(self,game_history_id,rating):
        """
        updates users rating for game 

        Args:
            game_history_id(int): entry to update
            rating(int): rating for the game (1-10)
        """

        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                cursor.callproc('UpdateGameRating',(game_history_id,rating))

                conn.commit()

    def update_date_start_or_end(self,game_history_id,input_date,start_date):
        """
        Converts user input into date format and inserts into start date for relevant game history entry

        Args:
            game_history_id(int): entry to update
            input_date(date): date to input
            start_date(bool): false = input to end date, true = input to start date
        """

        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                if start_date:
                    cursor.callproc('UpdateGameStartDate',(game_history_id,input_date))
                else:
                    cursor.callproc('UpdateGameEndDate',(game_history_id,input_date))

                conn.commit()

    def update_time_played(self,game_history_id, time_played):
        """
        Adds time played to currently stored time played

        Args:
            game_history_id(int): entry to update
            time_played(int): time played in seconds
        """

        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                cursor.callproc('UpdateTimePlayed',(game_history_id,time_played))

                conn.commit()

    def get_user_game_history(self, user_id):
        """
        gets all games in a users history

        Args:
            user_id (int): the users ID
        """

        with self.db.connection_handler() as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.callproc('GetUserGameHistory', (user_id,))
                for result in cursor.stored_results():
                    results = result.fetchall()
        
        #print(results)
        return results
    
    def get_game_history_by_id(self, game_history_id):
        """
        gets the information for a paticular game history entry 

        Args
            game_history_id (int): the game history ID
        """

        with self.db.connection_handler() as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.callproc('GetGameHistory', (game_history_id,))
                result = cursor.fetchall() 
                for result in cursor.stored_results():
                        results = result.fetchall()

        return results
    
    def get_game_notes(self, game_history_id):
        """
        gets any notes a user may have for a game

        Args:
            game_history_id (int): the game history ID

        Returns:
            results: The note for the game
        """

        with self.db.connection_handler() as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.callproc('GetNote', (game_history_id,))
                result = cursor.fetchall() 
                for result in cursor.stored_results():
                        results = result.fetchall()
        
        return results
    
    def get_game_info(self,game_id):
        """
        gets info for a game and users info 

        Args:
            game_id (int): the game ID 
            game_history_id (int): the game history ID

        Returns:
            results: The note for the game
        """
         
        with self.db.connection_handler() as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.callproc('GetGameInfo', (game_id,))
                result = cursor.fetchall() 
                for result in cursor.stored_results():
                        results = result.fetchall()
        
        return results
    
    def get_updated_history(self, game_history_id):
        """
        gets any changes made to the game_history after editing

        Args:
            game_history_id (int): the game history ID

        Returns: 
            results: the updated history values, rating status etc
        """

        with self.db.connection_handler() as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.callproc('GetUpdatedHistory', (game_history_id,))
                result = cursor.fetchall() 
                for result in cursor.stored_results():
                        results = result.fetchall()
        
        return results
        
    def search_game_by_title_in_db(self, game_name):
        """
        Executes the search query to find top 5 games that match the search.

        Args:
            game_name (str): the search query

        Returns:
            list: top 5 games that match the search, or an empty list if no matches are found
        """
        with self.db.connection_handler() as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.callproc('SearchGamesByTitle', (game_name,))
                result = cursor.fetchall() 
                for result in cursor.stored_results():
                        results = result.fetchall()
                    
    
        return results
                     
    def check_game_exists_in_history_db(self, user_id, game_id):
        """
        Checks if a game already exists in a user's history 

        Args:
            user_id(int): the users ID
            game_id(int): id of the game to check

        Returns:
            results: game_history_id if it exists, None if not 
        """
        with self.db.connection_handler() as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.callproc('CheckGameExistsInHistory', (user_id,game_id,))
                result = cursor.fetchall() 
                for result in cursor.stored_results():
                        results = result.fetchall() 
        return results
    
    def delete_game_from_history(self,game_history_id):
        """
        Removes the selected entry from a users log

        game_history_id: the entry to delete 
        """

        with self.db.connection_handler() as conn:
            with conn.cursor() as cursor:
                cursor.callproc('DeleteGameHistoryEntry', (game_history_id,))

                conn.commit()

    def retrive_user_vectors(self,user_id):
        """
        Retrives the vectors for the games in the users log. Used for reccomendations

        Args:
            user_id(int): the users ID

        Returns:
            results: dictionary of vectors for games in users log
        """

        with self.db.connection_handler() as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.callproc('GetUserVectors', (user_id,))
                result = cursor.fetchall() 
                for result in cursor.stored_results():
                        results = result.fetchall() 
        return results
    
    def retrieve_reccomendation_vectors(self,user_id, recent_releases = False):
        """
        Retrieves the vectors for the games that are considered for reccomendation. user_id is used to exclude games in users log
        Have to filter this down in some manner, so games are only considered if their rating > 70 and they have at least one genre/game mode

        Args:
            user_id(int): the users ID
            recent_releases(bool): indicates if reccomending recent games or not

        Returns:
            results: dictonary of vectors for game reccomendations
        """

        with self.db.connection_handler() as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.callproc('GetGameSuggestions', (user_id,recent_releases,))
                result = cursor.fetchall() 
                for result in cursor.stored_results():
                        results = result.fetchall() 
        return results
    
    def retrieve_reccomendation_details(self,json_array):
        """
        Retrives details for the reccomended games

        Args:
            id_array(json_array): json array of ids to fetch 
        """
        with self.db.connection_handler() as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.callproc('GetGameDetailsBatchJSON',(json_array,))
                result = cursor.fetchall() 
                for result in cursor.stored_results():
                        results = result.fetchall() 
        return results





       
    

