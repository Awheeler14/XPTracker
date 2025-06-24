import requests 
import time
from api import GameDataParser
import requests

class TwitchAuthenticator:
    """
    Contains methods to authenticate with the Twitch API and retrieve an access token.

    Attributes:
        client_id (str): The client ID for the Twitch API.
        client_secret (str): The client secret for the Twitch API.
        access_token (str): The access token obtained after authentication.
        token_expiry (float): The time when the access token will expire.
        token_url (str): The URL to request the access token.
    
    Methods:
        authenticate(): Authenticate with the Twitch API and retrieve an access token.
        get_access_token(): Return the access token, if available.
        is_token_expired(): Check if the current token is expired or about to expire.

    """
    def __init__(self, client_id, client_secret):
        """
        Initialize the TwitchAuthenticator with client ID and client secret.
        """
        self.client_id = client_id
        self.client_secret = client_secret
        self.access_token = None
        self.token_expiry = None  # Time when the token will expire
        self.token_url = "https://id.twitch.tv/oauth2/token"

    def authenticate(self):
        """
        Authenticate with the Twitch API and retrieve an access token.
        """
        params = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "grant_type": "client_credentials"
        }
        
        response = requests.post(self.token_url, params=params)
        
        if response.status_code == 200:
            data = response.json()
            self.access_token = data.get("access_token")
            expires_in = data.get("expires_in")
            self.token_expiry = time.time() + expires_in  # Current time + token lifespan
        else:
            raise Exception(f"Authentication failed: {response.json()}")

    def get_access_token(self):
        """
        Return the access token, refreshing it if necessary.

        Returns:
            str: The access token for the Twitch API.
        """
        if not self.access_token or self.is_token_expired():
            self.authenticate()
        return self.access_token

    def is_token_expired(self):
        """
        Check if the current token is expired or about to expire.

        Returns:
            bool: True if the token is expired or about to expire, False otherwise.
        """
        if self.token_expiry is None:
            return True
        # Refresh if the token will expire in the next 60 seconds
        return time.time() >= self.token_expiry - 60
    
class IGDBAPI:
    def __init__(self, client_id, twitch_authenticator, test_mode=False):
        self.client_id = client_id
        self.twitch_authenticator = twitch_authenticator
        self.base_url = "https://api.igdb.com/v4"
        self.test_mode = test_mode
        self.max_retries = 3  # Number of times to retry in case of failure

    def post_request(self, url_end, body):
        """
        Make a POST request to the IGDB API.
        Handles rate limits, retries, and exceptions.
        """
        url = f"{self.base_url}{url_end}"
        access_token = self.twitch_authenticator.get_access_token()

        headers = {
            "Client-ID": self.client_id,
            "Authorization": f"Bearer {access_token}",
        }

        for attempt in range(self.max_retries):
            try:
                response = requests.post(url, headers=headers, data=body)

                if response.status_code == 200:
                    return response.json()

                elif response.status_code == 429:
                    retry_after = int(response.headers.get("Retry-After", 5))
                    print(f"Rate limit hit. Retrying in {retry_after} seconds...")
                    time.sleep(retry_after)
                    continue  # Retry the request

                else:
                    print(f"Request failed. Status code: {response.status_code}, Message: {response.text}")
                    return None

            except requests.RequestException as e:
                print(f"Request error: {e}")
                time.sleep(1)  # Small delay before retry

        print(f"Request to {url_end} failed after {self.max_retries} retries.")
        return None
  
    def search_by_title(self, title):
        """
        Search for main games by title using the IGDB API.

        Args:
            title (str): The title of the game to search for.

        Returns:    
            list: A list of game data dictionaries.
        """

        url_end = "/games"
        body = f'''
            fields id,
            name,
            release_dates.date,
            summary,
            rating,
            cover.url,
            genres.name,
            involved_companies.company.name,
            involved_companies.company.logo.url,
            similar_games,
            keywords.name,
            game_modes.name,
            age_ratings.rating_category.rating,
            age_ratings.organization.name,
            game_type;
            search "{title}";
            where game_type = (0,8) & version_parent = null;
        '''

        game_data = self.post_request(url_end, body)
        print (game_data)
        if game_data:
            return game_data[0]
        else:
            print(f"No main game found with title: {title}")
            return None
        
    def search_by_id(self, game_id):
        """
        Search for a game by its ID using the IGDB API.

        Args:
            game_id (int): The ID of the game to search for.

        Returns:
            dict: A dictionary containing the game data.
        """

        url_end = "/games"
        body = f'''
            fields id,
            name,
            release_dates.date,
            summary,
            rating,
            cover.url,
            genres.name,
            involved_companies.company.name,
            involved_companies.company.logo.url,
            similar_games,
            keywords.name,
            game_modes.name,
            age_ratings.rating_category.rating,
            age_ratings.organization.name,
            game_type;
            where id = {game_id} & game_type = (0,8) & version_parent = null;
        '''

        game_data = self.post_request(url_end, body)

        if game_data:
            return game_data
        else:
            print(f"No game found with ID: {game_id}")
            return None
        
       
    def get_time_to_beat(self,game_id):
        """
        Get the time to beat the game.

        Args:
            game_id (int): The ID of the game.

        Returns:
            dict: The time to beat the game.
        """
    
        url_end = "/game_time_to_beats"

        body = f'fields normally; where game_id ={game_id};'

        time_data = self.post_request(url_end, body)

        if time_data:
            return time_data
        else:
            # print(f"No time to beat found for game ID: {game_id}")
            return None
        
    def fetch_all_game_ids(self):
        """
        Fetch all the game IDs from IGDB, starting from the last processed one.
        """
        from database import load_progress  # Import here to ensure it loads the progress correctly

        # Load the last processed game ID
        last_processed_game_id = load_progress()
        print(f"Last processed game ID: {last_processed_game_id}")

        # If no progress is found, start from game ID 1
        if last_processed_game_id is None:
            last_processed_game_id = 1
            print("No progress found. Starting from game ID 1.")
        
        game_ids = []
        page = 0
        limit = 1000 if self.test_mode else None  # Set limit to 100 when test_mode is True

        while limit is None or len(game_ids) < limit:  # Ensure it check the limit only if it's not None
            url_end = "/games"
            fetch_limit = min(500, limit - len(game_ids)) if limit else 500 
            body = f'''
                fields id;
                limit {fetch_limit};
                offset {page * 500};
            '''
            game_data = self.post_request(url_end, body)

            if game_data:
                # If the game_id is greater than the last processed one, add to the list
                for game in game_data:
                    if 'id' in game:
                        game_id = game['id']
                        if last_processed_game_id and game_id >= last_processed_game_id:
                            game_ids.append(game_id)

                if len(game_data) < 500:
                    break  # Stop if fewer than 500 results (last page reached)

                page += 1
            else:
                print("Error fetching game IDs.")
                break

        return game_ids
    
    def fetch_rating_counts(self, id_array):
        """
        Populate database with rating counts (used to filter games in recommender system).
        Returns a dictionary of {game_id: rating_count}.
        """
        rating_count_dictionary = {}
        fetch_limit = 500

        for i in range(0, len(id_array), fetch_limit):
            id_chunk = id_array[i:i+fetch_limit]

            ids_string = ','.join(map(str, id_chunk))
            url_end = "/games"
            body = f'''
                fields id, rating_count;
                where id = ({ids_string});
                limit {len(id_chunk)};
            '''

            response = self.post_request(url_end, body)

            if response:
                for game in response:
                    game_id = game.get('id')
                    rating_count = game.get('rating_count', 0)  # default to 0 if not available
                    rating_count_dictionary[game_id] = rating_count
            else:
                print(f"Failed to fetch rating counts for IDs: {id_chunk}")

        return rating_count_dictionary

        
        
        
   
