from flask import Blueprint, request, jsonify, abort
from api import ProfilePicHandlerFrontend


# Handles uploading a new profile picture 
def create_profile_routes(profile_handler: ProfilePicHandlerFrontend):
    # Create a Blueprint for modular routing
    profile_bp = Blueprint("profile", __name__)
    
    @profile_bp.route('/upload_profile_pic', methods=['POST'])
    def upload_profile_pic():
        if 'file' not in request.files:
            abort(400, "No file part in the request.")
        
        file = request.files['file']
        username = request.form.get('username')

        if not username:
            abort(400, "Username is required.")

        file_path = profile_handler.save_picture(username, file)
        return jsonify({"message": "Profile picture uploaded successfully.", "file_path": file_path}), 200

    return profile_bp  # Return the blueprint instance