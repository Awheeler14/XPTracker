import bcrypt
import re
from database import UserDataHandler

class UserCreator:
    """
    A class to handle the creation of a new user 
    """
    def __init__(self, host, user, password):
        
        self.data_handler = UserDataHandler(host, user, password)

    def verify_email(self,email):
        """
        Ensures the email is in a valid format and doesnt already exist in the datbase

        Args:   
            email(str): the email to verift

        Returns:
            str: the email if it is valid
        """
        # Regex pattern for validating email, ensures it follows standard email format 
        pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

        #if email is valid, check it doesnt already exist in the db
        if re.match(pattern, email):
           if not self.data_handler.check_email_exists(email):
               return email  
           else:
                raise ValueError(
                    "Email already exists in the datbase"
                )       
        else:
            raise ValueError(
                   "Ensure email is in a valid format"          
            )
    
    def verify_username(self, username):
        
        # allows upercase/lowercase letters, underscores and must be between 3 and 20 chars
        pattern = r"^[a-zA-Z0-9_]{3,20}$"

        #if username is valid, check it doesnt already exist in the db 
        if re.match(pattern, username):
            if not self.data_handler.check_username_exists(username):
                return username
            else:
                raise ValueError(
                    "Username already exists in the datbase"
                )
        else:
            raise ValueError(
                   "Ensure username is in a valid format, username must be between 3-20 characters and contain only numbers, letters and underscores"          
            )
        
    def create_user(self,email,username,user_password,verify_password):
        """
        Inserts user data into the mysql database
        """

        if user_password != verify_password:
            raise ValueError("Passwords, do not match")

        email = self.verify_email(email)
        username = self.verify_username(username)
        user_password = verify_and_hash_password(user_password)

        self.data_handler.insert_user_data(email,username,user_password)

class UserManagement:
    """
    Handles user managment, like checking the passwords match 
    """
    def __init__(self, host, user, password):
        self.data_handler = UserDataHandler(host, user, password)

    def check_password(self,user_name,input_password):
        """
        Checks the inputted password matches the stored password
        Args:   
            user_name(str): the username
            input_password(str): the password typed by the user 

        Returns:
            int: the userID if the passwords match 
        """
        user_id = self.data_handler.get_user_id(user_name)
        #print(user_id)

        if user_id is None:
            return None

        hashed_password = self.data_handler.check_passwords_match(user_id)

        if hashed_password and bcrypt.checkpw(input_password.encode(), hashed_password.encode()):  
            return user_id
        else:
            return None
        
    def update_password(self,user_id,input_password,verify_password, new_password):
        """
        Handles updating the users password
        """
        if input_password != verify_password:
            raise ValueError("Passwords, do not match")
        
        if input_password == new_password:
            raise ValueError("New password cannot be the same as old password")

        if self.check_password(user_id,input_password):
            new_password = verify_and_hash_password(new_password)
            self.data_handler.update_password(user_id,new_password)
            return True
        else:
            return False
        
    def get_user(self,user_id):
        """
        Gets the relevant information for the user if the userID exists

        Args:   
            user_id(int): id of the user 

        Returns:
            the relevant user information
        """
        if user_id is None:
            return None
        
        return self.data_handler.get_user_information(user_id)


def verify_and_hash_password(password):
    """
    Makes sure the password is valid, hashses it if it is 
    """
        
    #password must contain at least 10 chars, less than 45 chars, at least one number, a special char and upper and lower case letters
    pattern = r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{10,45}$"

    if re.match(pattern,password):
        return bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))

    else:
        raise ValueError(
            "Ensure password has at least 10 characters, contains uppercase and lowercase letters, "
            "includes at least one number, and has at least one special character."
        )
        
    


        
        
