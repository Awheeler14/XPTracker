import threading
from .reccomender_engine import NearestNeighbourReccomenderEngine

class UserReccomendationManager:
    """
    Handles reccomendations for all active users, signalling when they are ready
    """
    def __init__(self, reccomender_engine: NearestNeighbourReccomenderEngine):
        self.reccomender = reccomender_engine
        self.user_reccomendations = {}
        self.lock = threading.Lock()

    def start_reccomendations(self, user_id: int, new_recs = False):
        with self.lock:
            if user_id in self.user_reccomendations and self.user_reccomendations[user_id]["ready"] and not new_recs:
                return
            
            # set initial "not ready" state so can check state without interuprting locked thread 
            self.user_reccomendations[user_id] = {
                'ready': False,
                'recommendations': None,
                'recent': None
            }

        # Start fetching reccomendations in background, as can take a moment
        def background_recs():
            recs = self.reccomender.provide_recommendations(user_id)
            recent = self.reccomender.provide_recommendations(user_id, True)

            with self.lock:
                self.user_reccomendations[user_id] = {
                    'ready': True,
                    'recommendations': recs,
                    'recent': recent
                }

        threading.Thread(target=background_recs).start()


    # Gets reccomendations
    def get_recommendations(self, user_id: int):
        with self.lock:
            if self.user_reccomendations.get(user_id, {}).get('ready', False):
                return self.user_reccomendations[user_id]
            return None