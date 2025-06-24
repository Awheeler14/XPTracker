from flask import Blueprint, request, jsonify, abort
from api import UserToGameHandlerFrontend
from reccomendations import reccomendation_manager

def user_game_routes(game_handler: UserToGameHandlerFrontend):
    # Create a Blueprint for modular routing
    game_bp = Blueprint("game", __name__)
    
    # Adds a new game to the users history 
    @game_bp.route('/add_game_to_history', methods=['POST'])
    def add_game_to_history():
        data = request.get_json()
        
        if not data:
            abort(400, "Invalid request. JSON data is required.")
        
        user_id = data.get("user_id")
        game_id = data.get("game_id")
        status = data.get("status")
        
        if user_id is None or game_id is None or status is None:
            abort(400, "Missing required fields: user_id, game_id, status.")
        
        try:
            data = game_handler.add_game_for_user(user_id, game_id, status)
            return jsonify(data), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

        reccomendation_manager.start_reccomendations(int(user_id),new_recs=True)

    # Updates status for a game in the history
    @game_bp.route('/update_status', methods = ['POST'])
    def update_game_status():
        data = request.get_json()

        if not data:
            abort(400, "Invalid request. JSON data is required.")

        game_history_id = data.get("game_history_id")
        status = data.get("status")

        if game_history_id is None or status is None:
            abort(400, "Missing required fields: game_history_id, status")

        try:
            game_handler.update_status_for_user(game_history_id,status)
            return jsonify({"message": "Status updated successfully."}), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

    #Updates rating for a game 
    @game_bp.route('/update_rating', methods = ['POST'])
    def update_game_rating():
        data = request.get_json()

        if not data:
            abort(400, "Invalid request. JSON data is required.")

        game_history_id = data.get("game_history_id")
        rating = data.get("rating")

        if game_history_id is None or rating is None:
            abort(400, "Missing required fields: game_history_id, rating")

        try:
            game_handler.update_rating_for_user(game_history_id,rating)
            return jsonify({"message": "Rating updated successfully."}), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

    # Updates dates for a game 
    @game_bp.route('/update_date', methods = ['POST'])
    def update_game_date():
        data = request.get_json()

        if not data:
            abort(400, "Invalid request. JSON data is required.")

        game_history_id = data.get("game_history_id")
        date = data.get("date")
        start_date = data.get("start_date")

        if game_history_id is None or start_date is None:
            abort(400, "Missing required fields: game_history_id, date, start_date(bool)")

        try:
            game_handler.update_end_or_start_date_for_game(game_history_id,date,start_date)
            if start_date == True:
                return jsonify({"message": "start date updated successfully."}), 200
            elif start_date == False:
                return jsonify({"message": "end date updated successfully."}), 200
            else:
                return jsonify({"message": "start date must be a bool, true to update start date, false to update end date"}), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

    # Add time played for a game 
    @game_bp.route('/add_time_played', methods = ['POST'])
    def add_time_played():
        data = request.get_json()

        if not data:
            abort(400, "Invalid request. JSON data is required.")

        game_history_id = data.get("game_history_id")
        hours = data.get("hours")
        minutes = data.get("minutes")

        if game_history_id is None or hours is None or minutes is None:
            abort(400, "Missing required fields: game_history_id, hours, minutes")

        try:
            game_handler.update_time_played_for_user(game_history_id,hours, minutes)
            return jsonify({"message": "time played added successfully."}), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

    # Hets the entire game history for a user 
    @game_bp.route('/get_user_game_history', methods = ['GET'])
    def get_user_game_history():
        user_id = request.args.get("user_id", type=int)

        if user_id is None:
            abort(400, "Missing required fields: user_id")

        # Start reccomendations process for user
        if user_id not in reccomendation_manager.user_reccomendations:
            reccomendation_manager.start_reccomendations(int(user_id))

        try:
            data = game_handler.get_user_game_history(user_id)
            return jsonify(data), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

    # Gets information on a specific game for a user 
    @game_bp.route('/get_game_history', methods=['GET'])  
    def get_game_history():
        game_history_id = request.args.get("game_history_id", type=int)

        if game_history_id is None:
            abort(400, "Missing required fields: game_history_id")

        try:
            data = game_handler.get_game_history(game_history_id)
            return jsonify(data), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

    # Gets notes for a game 
    @game_bp.route('/get_game_notes', methods = ['GET'])
    def get_game_notes():
        game_history_id = request.args.get("game_history_id", type=int)

        if game_history_id is None:
            abort(400, "Missing required fields: game_history_id")

        try:
            data = game_handler.get_game_notes(game_history_id)
            return jsonify(data), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

    # Gets generic information for a game 
    @game_bp.route('/get_game_info', methods = ['GET'])
    def get_game_info():
        game_id = request.args.get("game_id", type=int)

        if game_id is None:
            abort(400, "Missing required fields: game_id")

        try:
            data = game_handler.get_game_info(game_id)
            return jsonify(data), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

    # Gets the updated history for a game 
    @game_bp.route('/updated_history', methods = ['GET'])
    def get_updated_history():
        game_history_id = request.args.get("game_history_id", type=int)

        if game_history_id is None:
            abort(400, "Missing required fields: game_history_id")

        try:
            data = game_handler.get_updated_history(game_history_id)
            return jsonify(data), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

    # Handles users searching for games 
    @game_bp.route('/search_games', methods = ['POST'])
    def search_game_by_title():
        data = request.get_json()

        if not data:
            abort(400, "Invalid request. JSON data is required.")

        game_name = data.get("game_name")

        if game_name is None:
            abort(400, "Missing required fields: game_name")

        try:
            data = game_handler.create_search_query(game_name)
            return jsonify(data), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

    # Checks if a game is in a users history (used with search functionality)
    @game_bp.route('/check_game_in_history', methods = ['GET'])
    def check_game_in_history():
        user_id = request.args.get("user_id", type = int)
        game_id = request.args.get("game_id", type=int)

        if user_id is None:
            abort(400, "Missing required fields: user_id")

        if game_id is None:
            abort(400, "Missing required fields: game_id")

        try:
            data = game_handler.check_game_exists_in_history(user_id, game_id)
            return jsonify(data), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

    # Removes the selected game from a users history
    @game_bp.route('/delete_game_from_history', methods = ['DELETE'])
    def delete_game_from_history():
        game_history_id = request.args.get("game_history_id", type = int)
        user_id = request.args.get("user_id",type = int)

        if game_history_id is None:
            abort(400, "Missing required fields: game_history_id")

        try:
            game_handler.delete_game(game_history_id)
            return jsonify({"message": "Game deleted from history successfully"}), 200
        except Exception as e:
            abort(500, f"An error occurred: {str(e)}")

        reccomendation_manager.start_reccomendations(int(user_id),True)

    # Attempts to fetch game reccomendations
    @game_bp.route('/fetch_reccomendations', methods = ['GET'])
    def fetch_reccomendations():
        user_id = request.args.get("user_id", type = int)

        if user_id is None:
            abort(400, "Missing required fields: user_id")
        
        user_recs = reccomendation_manager.get_recommendations(user_id)
    
        if user_recs is None:
            abort(423, "Recommendations not ready!")

        return user_recs, 200

    return game_bp  # Return the blueprint instance