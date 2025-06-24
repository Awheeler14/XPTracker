from flask import Blueprint, request, jsonify, abort, send_file
from api import UserCreaterFrontend, UserManagementFrontend
import os
from reccomendations import reccomendation_manager

# Routes for creating a new user 
def create_user_routes(user_handler: UserCreaterFrontend):
    user_creator_bp = Blueprint("user_creator", __name__)

    # Handles the creation of a new user 
    @user_creator_bp.route('/create_user', methods=['POST'])
    def create_new_user():
        data = request.get_json()
        
        if not data:
            abort(400, "Invalid request. JSON data is required.")

        email = data.get("email")
        username = data.get("username")
        password = data.get("password")
        verify_password = data.get("verify_password")

        if email is None or username is None or password is None:
            abort(400, "Missing required fields: email, username, password")

        try:
            user_handler.create_user_frontend(email,username,password,verify_password)
            return jsonify({"message": "new user added succesfully."}), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

    return user_creator_bp

# Routes to handle user management (checking passwords, changing details etc)
def user_management_routes(user_handler: UserManagementFrontend):
    user_management_bp = Blueprint("user_manager",__name__)

    @user_management_bp.route('/check_passwords_match', methods=['POST'])
    # Checks inputted password matches the stored passwords 
    def check_passwords_match():
        data = request.get_json()
        
        if not data:
            abort(400, "Invalid request. JSON data is required.")

        user_name = data.get("user_name")
        input_password = data.get("input_password")

        if not user_name or not input_password:
            abort(400, "Missing required fields: user_name, input_password")

        try:
            user_id = user_handler.check_passwords(user_name, input_password)

            if user_id:
                return jsonify({"success": True, "user_id": user_id}), 200  # Return user_id on success
            else:
                return jsonify({"success": False, "message": "Invalid username or password"}), 401  # Use 401 for unauthorized access

        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")
    
    # Route to update the users passwords 
    @user_management_bp.route('/update_password',methods = ['POST'])
    def update_users_password():
        data = request.get_json()
        
        if not data:
            abort(400, "Invalid request. JSON data is required.")

        user_id = data.get("user_id")
        input_password = data.get("input_password")
        verify_password = data.get("verify_password")
        new_password = data.get("new_password")

        try:
            succsesful_update = user_handler.update_password(user_id,input_password,verify_password,new_password)

            if succsesful_update:
                return jsonify({"message": "New Password Saved!"}), 200
            else:
                return jsonify({"message": "Inputted password does not match current password"}), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

    # Gets information for a user based on user id 
    @user_management_bp.route('/get_user', methods=['GET'])
    def get_user():
        user_id = request.args.get('user_id')

        if not user_id:
            abort(400, "Missing required fields: user_id")

        # Call the method to retrieve the user information
        result = user_handler.get_user(user_id)

        if result is None:
            abort(404, "User not found")

        username, profile_picture = result

        # Set a default profile picture if none exists
        if profile_picture is None:
            profile_picture = "C:\\Users\\alfie\\OneDrive\\Documents\\Computer science\\Dissertation project\\ProfilePics\\blank-profile-picture-DEFAULT.png"


        # Return the username and a URL to the profile picture
        return jsonify({
            "username": username,
            "profile_picture": f"http://192.168.1.100:5000/profile_picture?path={profile_picture}"
        })

    # Provide profile picture for the app 
    @user_management_bp.route('/profile_picture', methods=['GET'])
    def serve_profile_picture():
        # Get the file path from the query parameter
        profile_picture_path = request.args.get('path')

        if not profile_picture_path:
            abort(400, "Missing profile picture path")

        # Check if the file exists
        if os.path.exists(profile_picture_path):
            return send_file(profile_picture_path, mimetype='image/jpeg')
        else:
            abort(404, "File not found")

    return user_management_bp