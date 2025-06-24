import pandas as pd
import numpy as np
import json
from sklearn.neighbors import NearestNeighbors
from database import UserGamesHandler
import time

class NearestNeighbourReccomenderEngine:
    """
    Handles reccomendations for users using NearestNeighbour cosine. Currently can do 'For You' and 'Recent Releases'
    """
    def __init__(self,data_handler: UserGamesHandler):
        self.data_handler = data_handler
    
    def provide_recommendations(self,user_id,recent_releases = False):
        """
        Provides reccomendations of games for users 
        """
        # Timing testing
        #start_time = time.time()

        # Retrieve data 
        rec_data = self.data_handler.retrieve_reccomendation_vectors(user_id,recent_releases)
        user_data = self.data_handler.retrive_user_vectors(user_id)

        # Create DataFrames
        df = pd.DataFrame(rec_data)
        user_df = pd.DataFrame(user_data)

        # Convert binary string to numpy array
        def string_to_vector(s):
            return np.array([int(ch) for ch in s])
        
        # Convert all genre and mode strings into numpy arrays for recommendation data
        genre_vectors = np.array([string_to_vector(x) for x in df['genre_vector']]) 
        mode_vectors = np.array([string_to_vector(x) for x in df['mode_vector']])

        # Concatenate genre and mode vectors horizontally to form feature vectors
        X = np.hstack([genre_vectors, mode_vectors])

        # Convert user vectors, filter out rows without user ratings
        user_df = user_df.dropna(subset=['rating'])
        user_df['rating'] = pd.to_numeric(user_df['rating'], errors='coerce')
        user_df = user_df.dropna(subset=['rating'])

        user_genre_vectors = np.array([string_to_vector(x) for x in user_df['genre_vector']])
        user_mode_vectors = np.array([string_to_vector(x) for x in user_df['mode_vector']])
        user_combined_data = np.hstack([user_genre_vectors, user_mode_vectors])

        # Extract ratings (as weights) and compute a weighted average vector to create a user profile
        ratings = user_df['rating'].to_numpy().reshape(-1, 1)
        weighted_vector = np.average(user_combined_data, axis=0, weights=ratings.flatten())

        # Reshape for NearestNeighbors 
        user_vector = weighted_vector.reshape(1, -1)
        n_samples = X.shape[0]
        n_neighbors = min(15, n_samples)

        # Build the model using cosine distance
        model = NearestNeighbors(n_neighbors=n_neighbors, metric='cosine')
        model.fit(X)

        distances, indices = model.kneighbors(user_vector)

        # Build recommendations
        recommendations = []
        for idx, dist in zip(indices[0], distances[0]):
            game_data_row = df.iloc[idx]
            recommendations.append({
                'gameID': game_data_row['gameID'],
                'similarity_distance': dist,
            })

        # extract gameIDs
        game_ids = [int(rec['gameID']) for rec in recommendations]

        # convert to JSON array string
        json_array_str = json.dumps(game_ids)

        game_details = self.data_handler.retrieve_reccomendation_details(json_array_str)

        # Dict keyed by gameID
        details_lookup = {row['gameID']: row for row in game_details}

        # Merge data back into reccomendations
        for rec in recommendations:
            game_id = rec['gameID']
            if game_id in details_lookup:
                rec.update(details_lookup[game_id])

        #end_time = time.time()
        #print(f"{'Recent' if recent_releases else 'Standard'} recommendations took {end_time - start_time:.2f} seconds.")

        return recommendations