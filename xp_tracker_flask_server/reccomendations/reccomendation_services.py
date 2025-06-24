from reccomendations import NearestNeighbourReccomenderEngine, UserReccomendationManager
from database import UserGamesHandler
from dotenv import load_dotenv
import os

load_dotenv(dotenv_path="python.env")

host = os.getenv("DB_HOST")
user = os.getenv("DB_USER")
password = os.getenv("DB_PASSWORD")

# create handlers
data_handler = UserGamesHandler(host, user, password)
recommender_engine = NearestNeighbourReccomenderEngine(data_handler)
reccomendation_manager = UserReccomendationManager(recommender_engine)