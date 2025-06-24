from datetime import datetime

class GameDataParser:
    """
    A class to parse and extract relevant information from game data.

    Attributes:
        data (dict): The data to parse.
        game_id (int): The ID of the game.
        game_name (str): The name of the game.
        release_date (str): The release date of the game.
        summary (str): The summary of the game.
        user_rating (float): The user rating of the game.
        poster_path (str): The path to the game's poster image.
        genre (str): The genre of the game.
        involved_companies (str): The developer of the game.
        age_rating (str): The age rating of the game.
        time_to_beat (int): The average time to beat the game.
    
    Methods:
        
    """
    
    def __init__(self, data, api):
        """
        Initialize the GameDataParser with the provided data.
        """
        self.data = data
        self.api = api
        
        self.game_id = self.data.get('id')
        self.game_name = self.data.get('name')
        self.release_date = self.convert_date(self.data.get('release_dates', []))
        self.summary = self.data.get('summary', 'N/A')
        self.user_rating = int(round(self.data.get('rating', 0), 0))
        self.cover_url = (f"https:{self.data.get('cover', {}).get('url', 'NO URL')}").replace("t_thumb", "t_cover_big")
        self.genres = self.genres = [{'id': genre.get('id'), 'name': genre.get('name', 'NO GENRE')} for genre in self.data.get('genres', [])]

        seen_ids = set()
        self.involved_companies = [
            {
                'id': company.get('company', {}).get('id'),
                'name': company.get('company', {}).get('name', 'NO COMPANY'),
                'logo_url': f"https:{company.get('company', {}).get('logo', {}).get('url', 'NO LOGO URL')}"
            }
            for company in self.data.get('involved_companies', [])
            if company.get('company', {}).get('id') not in seen_ids and not seen_ids.add(company.get('company', {}).get('id'))
        ]
        self.time_to_beat = self.get_time_to_beat()
        self.similar_games = self.data.get('similar_games', [])
        self.keywords = [{'id': keyword.get('id'), 'name': keyword.get('name', 'NO KEYWORD')} for keyword in self.data.get('keywords', [])]
        self.game_modes = [{'id': mode.get('id'), 'name': mode.get('name', 'NO GAME MODE')} for mode in self.data.get('game_modes', [])]

        self.age_ratings = [
        {
            'organization': rating.get('organization', {}).get('name', 'NO ORGANIZATION'),
            'rating': rating.get('rating_category', {}).get('rating', 'NO RATING')
        }
        for rating in self.data.get('age_ratings', [])
        if rating.get('organization', {}).get('id') == 2  # Only include PEGI ratings
        ]

    
    def convert_date(self, dates):
        """
        Convert the release date to a MySQL-compatible format. Selects the earliest release date from the list.

        Returns:
            str | None: The release date in 'YYYY-MM-DD' format or None if invalid.
        """

        # Extract valid Unix timestamps
        timestamps = [entry['date'] for entry in dates if isinstance(entry, dict) and isinstance(entry.get('date'), (int, float))]

        # Filter out negative and zero timestamps
        timestamps = [t for t in timestamps if t > 0]

        if not timestamps:
            return None  

        # Find the earliest valid timestamp
        earliest_timestamp = min(timestamps)
        
        try:
            earliest_datetime = datetime.fromtimestamp(earliest_timestamp)
        except OSError:
            return None  

        # Format the datetime object to MySQL date format (YYYY-MM-DD)
        return earliest_datetime.strftime('%Y-%m-%d')
                
    def convert_url(self, url, size = "t_cover_big"):
        """
        Convert the cover URL to a higher resolution.
        
        Args:
            cover_url (str): The original cover URL.
        
        Returns:
            str: The converted cover URL.
        """
        return url.replace("t_thumb", size)
      
    def get_time_to_beat(self):
        """
        Get the average time to beat the game in hours.

        Returns:
            str: The average time to beat the game rounded to hours, or None if not available.
        """
        time_to_beat_dict = self.api.get_time_to_beat(self.game_id)  
        if time_to_beat_dict:  # Check if the API returned data
            normally = time_to_beat_dict[0].get('normally')  # Extract the 'normally' value
            if normally:
                # Round to the nearest hour
                hours = round(normally / 3600)
                return hours
        return 0
    
    def get_parsed_data(self):
        """
        Returns a dictionary with all the parsed game data.

        Returns:
            dict: A dictionary containing the parsed game data.
        """
        return {
            "game_id": self.game_id,
            "game_name": self.game_name,
            "release date": self.release_date,
            "summary": self.summary,
            "user_rating": self.user_rating,
            "cover_url": self.cover_url,
            "genres": self.genres,
            "involved_companies": self.involved_companies,
            "time_to_beat": self.time_to_beat,
            "similar_games": self.similar_games,
            "keywords": self.keywords,
            "game_modes": self.game_modes,
            "age_rating": self.age_ratings
        }

        
            
    
