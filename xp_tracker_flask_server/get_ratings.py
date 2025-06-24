# from database import GameDataHandler
# from api import IGDBAPI, TwitchAuthenticator
# # Should be a one off file. Need rating count for good reccomendations so trying to use batch processing to fetch and insert them all

# data_handler = GameDataHandler(client_id, client_secret,host,user,password)

# igdb_array = data_handler.GetAllGameIDSAPI()
# print(igdb_array[:30])
# print(len(igdb_array))

# igdb = IGDBAPI(client_id,TwitchAuthenticator(client_id, client_secret))

# rating_dictionary = igdb.fetch_rating_counts(igdb_array)
# ordered_rating_list = [(game_id, rating_dictionary.get(game_id, 0)) for game_id in igdb_array]

# print(ordered_rating_list[:30])
# print(len(ordered_rating_list))

# data_handler.EnterRatingCount(ordered_rating_list)

# print("UPDATE COMPLETE!")