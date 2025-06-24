import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'package:xp_tracker/config.dart';
import 'package:xp_tracker/pages/edit_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';

String getYearFromDate(String dateString) {
  final dateTime = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parse(dateString, true).toLocal();
  return DateFormat('dd/MM/yyyy').format(dateTime);
}

// Displays all the information for the game, want to include more than whats here but 
// Can navigate to the edit entry page from here so need to pass in the necessary info
class GameInfoPage extends StatefulWidget {
  final int gameID;
  final int? gameHistoryID; // Nullable
  final int? gameStatus; // Nullable
  final int? gameRating; // Nullable
  final String coverUrl; 
  final String title; 
  final String? dateEnd; // Nullable
  final String? dateStart; // Nullable

   const GameInfoPage({
    super.key, 
    required this.gameID, 
    this.gameHistoryID,
    this.gameStatus, // Nullable
    this.gameRating, // Nullable
    required this.coverUrl, // Nullable
    required this.title, // Nullable
    this.dateEnd, // Nullable
    this.dateStart, // Nullable
  });
  @override
  GameInfoPageState createState() => GameInfoPageState();
}

class GameInfoPageState extends State<GameInfoPage> {
  Map<String, dynamic>? gameData;
  bool isLoading = true;
  bool hasError = false;

  // updates game history information if navigating back to edit entry after making a change in game info
  int? updatedGameHistoryID;
  int? updatedGameStatus;
  int? updatedGameRating;
  String? updatedDateStart;
  String? updatedDateEnd;

  // Fetches game information and assigns the passed in variables to the local ones
  @override
  void initState() {
    super.initState();
    initializeGameInfo();
    updatedGameHistoryID = widget.gameHistoryID;
    updatedGameStatus = widget.gameStatus;
    updatedGameRating = widget.gameRating;
    updatedDateStart = widget.dateStart;
    updatedDateEnd = widget.dateEnd;

  }

  Future<void> initializeGameInfo() async {
    await fetchGameInfo(); 
    await checkGameHistory(); 
  }

  // mapping for age ratings too the local images 
  Widget getAgeRatingWidget(BuildContext context, String? ageRating) {
     final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    switch (ageRating) {
      case "PEGI Three":
        return Image.asset('assets/PEGI3.jpg', width: 295 / 6, height: 360 / 6);
      case "PEGI Seven":
        return Image.asset('assets/PEGI7.jpg', width: 295 / 6, height: 360 / 6);
      case "PEGI Twelve":
        return Image.asset('assets/PEGI12.jpg', width: 295 / 6, height: 360 / 6);
      case "PEGI Sixteen":
        return Image.asset('assets/PEGI16.jpg', width: 295 / 6, height: 360 / 6);
      case "PEGI Eighteen":
        return Image.asset('assets/PEGI18.jpg', width: 295 / 6, height: 360 / 6);
      default:
        return Icon(Icons.help_outline, size: 45, color: isDarkMode ? Colors.white70: Colors.black87,); // Placeholder icon
    }
  }
  
  // Checks if game in users history for the icon
  Future<void> checkGameHistory() async {
    if (updatedGameHistoryID == null) {
      final prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('userId');

      if (userId != null) {
        final url = Uri.parse('$baseUrl/check_game_in_history?user_id=$userId&game_id=${widget.gameID}');
        try {
          final response = await http.get(url);
          if (response.statusCode == 200) {
            final List<dynamic> jsonResponse = json.decode(response.body);
            
            if (jsonResponse.isNotEmpty) {
              final gameHistory = jsonResponse[0];
              setState(() {
                updatedGameHistoryID = gameHistory["game_historyID"];
                updatedGameStatus = gameHistory["status"];
                updatedGameRating = gameHistory["rating"];
                updatedDateStart = gameHistory["date_start"];
                updatedDateEnd = gameHistory["date_end"];
              });
            } else {
              log('No game history found, keeping default values.');
            }
          } else if (response.statusCode == 500) {
            // Handle the case when the game has been deleted from the log (server returns 500)
            log('Game has been deleted or there was a server error.');
            setState(() {
              updatedGameHistoryID = null;
              updatedGameStatus = null;
              updatedGameRating = null;
              updatedDateStart = null;
              updatedDateEnd = null;
            });
          } else {
            log('Error checking game history: ${response.statusCode}');
          }
        } catch (e) {
          log('Error making API call: $e');
          // Reset values in case of network error
        }
      } else {
        log('User ID not found in SharedPreferences.');
      }
    }
  }
  // Fetches game details 
  Future<void> fetchGameInfo() async {
    final url = Uri.parse('$baseUrl/get_game_info?game_id=${widget.gameID}');
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty) {
          setState(() {
            gameData = jsonResponse[0];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } 
    catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }finally {
    stopwatch.stop(); // Stop the timer no matter what (success or failure)
    //print('fetchGameInfo API call took ${stopwatch.elapsedMilliseconds} ms');
  }
}

  // Updates the game status information after an edit is made 
  Future<void> updateValues() async {
    if (updatedGameHistoryID == null) return;

    final url = Uri.parse('$baseUrl/updated_history?game_history_id=$updatedGameHistoryID');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);

        // Check if the list is not empty and then parse the first element
        if (jsonResponse.isNotEmpty) {
          final Map<String, dynamic> gameInfo = jsonResponse[0]; 

          setState(() {
            updatedGameStatus = gameInfo["status"];
            updatedGameRating = gameInfo["rating"];
            updatedDateStart = gameInfo["date_start"];
            updatedDateEnd = gameInfo["date_end"];

          });
        }
      }
    } catch (e) {     
      log("Failed to update values: $e");
    }
  }

  double containerWidth = 264 / 2.9;
  double containerHeight = 374 / 2.9;

  Widget buildScrollableList(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    // Parse the similar games list and create a dynamic scrollable list of similar games
    List<dynamic> similarGames = json.decode(gameData!["similar_games"]);

    return SizedBox(
      height: containerHeight + 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: similarGames.length,
        itemBuilder: (context, index) {
          var game = similarGames[index];

          // Skip games with null or empty game_name or release_date
          if (game['game_name'] == null || game['game_name'].isEmpty || game['release_date'] == null || game['release_date'].isEmpty) {
            return SizedBox(); // Return an empty widget to skip this game
          }

          // Truncate game name to 24 characters and add ellipsis if necessary
          String gameName = game['game_name'];
          if (gameName.length > 24) {
            gameName = '${gameName.substring(0, 24)}...';
          }

          // Wrap the entire column in InkWell for navigation
          return InkWell(
            onTap: () {
              // Navigate to the GameInfoPage with correct game data
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameInfoPage(
                    gameID: game['gameID'], 
                    coverUrl: game['cover_url'],
                    title: game['game_name'],
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: containerWidth,
                    height: containerHeight,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (game['cover_url'] != "https:NO URL" && game['cover_url'].isNotEmpty)
                          ? Image.network(
                              game['cover_url'],
                              width: containerWidth,
                              height: containerHeight,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.image, // Placeholder icon for missing image
                              size: 50,
                              color: isDarkMode ? Colors.grey: Colors.grey[800],
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Use a Text widget with maxLines set to 2 to allow wrapping
                  SizedBox(
                    width: containerWidth,
                    height: 50,
                    child: Text(
                      gameName,
                      style: TextStyle(color: isDarkMode ? Colors.white: Colors.black, fontWeight: FontWeight.bold),
                      maxLines: 2, // Allow up to 2 lines
                      overflow: TextOverflow.ellipsis, // Add ellipses when the text overflows
                      softWrap: true, // Ensure wrapping
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  } 

  // Creates the circle containing the rating from other users on IGDB
  Widget buildUserRating(double rating) {
    Color centerColor;
    Color borderColor;

    // Sets colour based on the rating range 
    if (rating >= 70) {
      centerColor = Colors.lightGreen; // Light green center
      borderColor = Color(0xFF006400); // Dark green border
    } else if (rating >= 40) {
      centerColor = Colors.orange; // Light orange center
      borderColor = Color(0xFF8B4500); // Dark orange border
    } else {
      centerColor = Colors.red; // Light red center
      borderColor = Color(0xFF5C0000); // Dark red border
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: centerColor,
        border: Border.all(
          color: borderColor,
          width: 4,
        ),
      ),
      child: Text(
        rating.toInt().toString(),
        style: TextStyle(
          color: borderColor,
          fontSize: 45,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF403C3D) : Colors.white,
      // App bar contatining back arrow and logo 
      appBar: AppBar(
        backgroundColor: isDarkMode ? Color(0xFF635F60) : Colors.grey[300], 
        automaticallyImplyLeading: true,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white: Colors.black,),
        title: Container(
          padding: const EdgeInsets.only(right: 0),
          child: Image.asset(
            'assets/Logo.png',
            height: 150,
            width: 150,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: isDarkMode ? Colors.white: Colors.black,),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      // Body is scrollable since page can be varying length 
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError || gameData == null
              ? Center(child: Text('Error loading game data', style: TextStyle(color: isDarkMode ? Colors.white: Colors.black,)))
              : SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(top:15.0, left: 15, right: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center, // Center the column horizontally
                          children: [
                            // Title at the top
                            Text(
                              gameData!["game_name"],
                              style: TextStyle(
                                color: isDarkMode ? Colors.white: Colors.black,
                                fontSize: 35,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center, // Center the title text
                              overflow: TextOverflow.visible, // Allow text to overflow visibly
                              softWrap: true, // Allow text to wrap to the next line
                            ),
                            const SizedBox(height: 16), 
                            // Row for the picture and date
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Game cover picture
                                Hero(
                                  tag: 'cover_${widget.gameID}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      widget.coverUrl,
                                      width: screenWidth / 2.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16), 
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center, 
                                    mainAxisAlignment: MainAxisAlignment.center, 
                                    children: [
                                      const SizedBox(height: 30),
                                      buildUserRating(gameData!["user_rating"]), 
                                      const SizedBox(height: 30),
                                      Text.rich(
                                        // Release date
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: "Released: ",
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white: Colors.black,
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text: getYearFromDate(gameData!["release_date"]),
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white70: Colors.black87,
                                                fontSize: 24,
                                                fontWeight: FontWeight.normal, 
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Games genres
                            const SizedBox(height: 15), 
                            Text(
                              gameData!["genres"], // Display the raw genres string as it is because already looks how I want it too 
                              style: TextStyle(
                                color: isDarkMode ? Colors.white: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center, // Center the text
                            ),
                            const SizedBox(height: 5),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    Container(
                      height: 2.0,
                      color: isDarkMode ? Color(0xFF5E5B5C) : Colors.grey[300],
                      width: screenWidth,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Game Modes available for this game 
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Game Modes: ", 
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: gameData!["game_mode"], 
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70: Colors.black87,
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 2.0,
                      color: isDarkMode ? Color(0xFF5E5B5C) : Colors.grey[300],
                      width: screenWidth,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          // Description of the game 
                          Text(
                            gameData!["description"], 
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70: Colors.black87,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.start, 
                          ),
                          const SizedBox(height: 25),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Titles on opposite sides
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            children: [
                             // Involved Companies section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Companies:",
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  // Check if companies_with_logos exists and isn't empty
                                  if (gameData?["companies_with_logos"] != null &&
                                      gameData!["companies_with_logos"].toString().isNotEmpty)
                                    ...gameData!["companies_with_logos"]
                                        .toString()
                                        .split(", ")
                                        .map<Widget>((company) {
                                      final match =
                                          RegExp(r"(.+?) \((https?:\/\/.+?)\)").firstMatch(company);
                                      if (match == null) return SizedBox(); // skip if parsing fails

                                      final companyName = match.group(1)!;
                                      final logoUrl = match.group(2)!;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Row(
                                          children: [
                                            logoUrl != "https:NO LOGO URL"
                                                ? ClipRRect(
                                                    child: Image.network(
                                                      logoUrl,
                                                      width: 40,
                                                      height: 40,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.business,
                                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                                    size: 40,
                                                  ),
                                            const SizedBox(width: 9),
                                            ConstrainedBox(
                                              constraints:
                                                  BoxConstraints(maxWidth: screenWidth * 0.45),
                                              child: Text(
                                                companyName,
                                                style: TextStyle(
                                                  color: isDarkMode ? Colors.white : Colors.black,
                                                  fontSize: 18,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    })
                                  else
                                    Text(
                                      "No companies listed.",
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white70 : Colors.black54,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),

                              // Right-aligned Time To Beat section
                              Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, 
                                  children: [
                                    Text(
                                      "Time To Beat:",
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      gameData!["time_to_beat"] == 0 
                                          ? "N/A" 
                                          : "${gameData!["time_to_beat"].toInt()} Hours",
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white70: Colors.black87,
                                        fontSize: 20,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Text(
                                      "Age Rating:",
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    getAgeRatingWidget(context,gameData!["age_rating"])
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "Similar Games:",
                            style: TextStyle(
                              color: isDarkMode ? Colors.white: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          buildScrollableList(context),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        // Takes to the edit page for the selected game 
        floatingActionButton: Transform.translate(
            offset: Offset(-10, -10), // Adjust the position slightly so its not right in the corner 
            child: FloatingActionButton(
              onPressed: () async {
                bool isDeleted = false;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEntryPage(
                      gameID: widget.gameID,
                      gameHistoryID: updatedGameHistoryID,
                      gameStatus: updatedGameStatus,
                      gameRating: updatedGameRating,
                      coverUrl: widget.coverUrl,
                      title: widget.title,
                      dateStart: updatedDateStart,
                      dateEnd: updatedDateEnd,
                      onSuccess: () {
                        Navigator.pop(context, true);
                      },
                      onDeleteSuccess: () {
                        Navigator.pop(context, true); // Deletion success callback
                        isDeleted = true;
                        setState(() {
                          updatedGameHistoryID = null;
                          updatedGameStatus = null;
                          updatedGameRating = null;
                          updatedDateStart = null;
                          updatedDateEnd = null;
                        });
                      },
                    ),
                  ),
                );
                if (result == true && !isDeleted) {
                  if (updatedGameHistoryID == null){
                    checkGameHistory(); // Only update values if it was a successful update
                  }
                  else{
                    updateValues();
                  }
                }
                //not sure why i need to reset this here but I think it solbes the problem 
                if (isDeleted){
                  isDeleted = false;
                }
              },
              backgroundColor: Colors.green, 
              // had to do this to stop the icon being the wrong colour after light mode was introduced
              foregroundColor: isDarkMode ? Color(0xFF4F378B): Colors.white,
              child: Icon(
                updatedGameHistoryID != null ? Icons.edit : Icons.add, // Edit icon if gameHistoryID is not null, otherwise Add icon
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Position it in the bottom-right corner
      );
  }
}
