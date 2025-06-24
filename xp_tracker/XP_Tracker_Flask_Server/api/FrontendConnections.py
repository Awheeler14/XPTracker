from flask import Flask, abort
from werkzeug.utils import secure_filename
import os
import glob
from datetime import datetime

app = Flask(__name__)
# Handles any processes needed for the api routes 

# Processes for the the profile picture
class ProfilePicHandlerFrontend:
    upload_folder = r"C:\Users\alfie\OneDrive\Documents\Computer science\Dissertation project\ProfilePics"
    extensions = {"png", "jpeg", "jpg"}

    def __init__(self, host, user, password):
        from database import UserDataHandler
        os.makedirs(self.upload_folder, exist_ok=True)
        self.data_handler = UserDataHandler(host, user, password)

    def validate_upload(self, file):
        """
        Ensures the uploaded file is a picture (png, jpeg, jpg), raises an exception if it isn't
        """
        if not file or '.' not in file.filename:
            abort(400, "Invalid file. No filename detected.")
        
        ext = file.filename.rsplit(".", 1)[1].lower()
        if ext not in self.extensions:
            abort(400, "Invalid file type. Only PNG and JPEG are allowed.")

    def save_picture(self, username: str, file) -> str:
        """
        Saves uploaded picture and updates file path in the database
        """
        self.validate_upload(file)

        # Secure the filename and determine the path
        ext = file.filename.rsplit(".", 1)[1].lower()
        filename = secure_filename(f"{username}.{ext}")
        file_path = os.path.join(self.upload_folder, filename)

        # Search and remove old profile picture (if any)
        old_files = glob.glob(os.path.join(self.upload_folder, f"{username}.*"))  # Match any file with the username
        for old_file in old_files:
            os.remove(old_file)  


        # Save the file
        file.save(file_path)

        # Update the database
        self.data_handler.insert_profile_pic_path(username, file_path)

        return file_path
    
class UserCreaterFrontend:
    """
    Handles setting up new users
    """
    def __init__(self, host, user, password):
        from database import UserCreator
        self.user_handler = UserCreator(host, user, password)

    def create_user_frontend(self,email:str ,username: str ,user_password:str, verify_password: str):
        """
        Creates a new user 
        """
        self.user_handler.create_user(email,username,user_password, verify_password)

class UserManagementFrontend:
    """
    Handles managing existing users (checking passwords, changing password etc)
    """
    def __init__(self, host, user, password):
        from database import UserManagement
        self.user_handler = UserManagement(host, user, password)

    def check_passwords(self,user_name: str,input_password: str):

        return self.user_handler.check_password(user_name,input_password)
    
    def update_password(self,user_id: int, input_password: str, verify_password: str, new_password: str):

        return self.user_handler.update_password(user_id, input_password, verify_password, new_password)
    
    def get_user(self,user_id:int):

        return self.user_handler.get_user(user_id)


class UserToGameHandlerFrontend:
    """
    Handles users adding and modifying games in their log
    """
    def __init__(self,host, user, password):
        from database import UserGamesHandler
        self.db_connection = UserGamesHandler(host,user,password)

    def add_game_for_user(self, user_id: int, game_id: int, status: int):
        """
        Adds game to a users log 
        """
        game_historyID = self.db_connection.add_game_to_list(user_id,game_id,status) 
        return game_historyID

    def update_status_for_user(self, game_history_id: int ,status: int):
        """
        Updates game status 
        """
        self.db_connection.update_status(game_history_id,status)

    def update_rating_for_user(self, game_history_id: int, status: int):
        """
        Updates users rating for a game 
        """
        self.db_connection.update_rating(game_history_id,status)

    def update_end_or_start_date_for_game(self, game_history_id: int, input_date: str, start_date: bool):
        """
        Updates start and end dates for games 
        """
        try:
            # If input_date is None or empty, set it to None 
            if input_date is None or input_date == "":
                date_to_input = None
            else:
                date_to_input = datetime.strptime(input_date, "%Y-%m-%d")
        except ValueError:
            raise ValueError("Ensure date is in valid format")

        self.db_connection.update_date_start_or_end(game_history_id, date_to_input, start_date)

    def update_time_played_for_user(self,game_history_id, hours_played:int,minutes_played:int):
        """
        Allows user to add time to the time played for a game 
        """
        time_to_add = 0 
        try:
            hours_played = hours_played * 3600
            minutes_played = minutes_played * 60

            time_to_add = hours_played + minutes_played

        except:
            raise ValueError(
                "ensure time played is in a valid format"
            )
        
        self.db_connection.update_time_played(game_history_id, time_to_add)

    def get_user_game_history(self,userID: int):
        """
        Gets all games in a users log 
        """
        return self.db_connection.get_user_game_history(userID)
    
    def get_game_history(self, game_history_id: int):
        """
        Gets information for one game in the log 
        """
        return self.db_connection.get_game_history_by_id(game_history_id)
    
    def get_game_notes(self, game_history_id: int):
        """
        Gets notes for a game 
        """
        return self.db_connection.get_game_notes(game_history_id)
    
    def get_game_info(self, game_id: int):
        """
        Gets the generic info for a game
        """
        return self.db_connection.get_game_info(game_id)
    
    def get_updated_history(self, game_history_id: int):
        """
        Used to get changes made in the status of a game 
        """
        return self.db_connection.get_updated_history(game_history_id)
    
    def create_search_query(self, game_name: str):
        """
        Use to Search for games by title 
        """
        return self.db_connection.search_game_by_title_in_db(game_name)
    
    def check_game_exists_in_history(self, user_id: int, game_id: int):
        """
        Checks if a game exists in a users history
        """
        return self.db_connection.check_game_exists_in_history_db(user_id,game_id)
    
    def delete_game(self, game_history_id: int):
        """
        Deletes a game from a users history 
        """
        self.db_connection.delete_game_from_history(game_history_id)