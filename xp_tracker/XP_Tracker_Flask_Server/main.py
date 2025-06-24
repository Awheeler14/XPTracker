from api import ProfilePicHandlerFrontend, UserToGameHandlerFrontend,UserCreaterFrontend, UserManagementFrontend, GameDataParser
from flask import Flask
from dotenv import load_dotenv
import os
from routes.upload_profile_routes import create_profile_routes
from routes.user_games_routes import user_game_routes
from routes.user_routes import create_user_routes, user_management_routes

app = Flask(__name__)

def main():

    # Personal details 
    load_dotenv(dotenv_path="python.env")

    host = os.getenv("DB_HOST")
    user = os.getenv("DB_USER")
    password = os.getenv("DB_PASSWORD")
    client_id = os.getenv("API_CLIENT_ID")
    client_secret = os.getenv("API_CLIENT_SECRET")

    # Loads all the bp 
    create_user_handler = UserCreaterFrontend(host, user, password)
    user_creator_bp = create_user_routes(create_user_handler)

    user_management_handler = UserManagementFrontend(host, user, password)
    user_managagment_bp = user_management_routes(user_management_handler)

    profile_handler = ProfilePicHandlerFrontend(host, user, password)
    profile_bp = create_profile_routes(profile_handler)
    
    user_game_handler = UserToGameHandlerFrontend(host, user, password)
    user_game_bp = user_game_routes(user_game_handler)

    
    # Register the blueprints
    app.register_blueprint(profile_bp)
    app.register_blueprint(user_game_bp)
    app.register_blueprint(user_creator_bp)
    app.register_blueprint(user_managagment_bp)


    print("Flask app started!")  
    
    # Start the Flask server (still in debug mode)
    app.run(host='0.0.0.0', port=5000, debug=True)  

if __name__ == "__main__":
    app = main()
    app.run(debug=True) 




