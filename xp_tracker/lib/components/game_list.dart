import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:xp_tracker/pages/edit_entry.dart';
import 'package:xp_tracker/pages/game_info.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';


// The games list on the quest log page

// I havent handled date formatting very well in flask so need to convert it here 
String getYearFromDate(String dateString) {
  final dateTime = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parse(dateString, true).toLocal();
  return DateFormat('yyyy').format(dateTime);
}

// Make sure title overflow 
String getTruncatedString(String title, int maxLength) {
  if (title.length > maxLength) {
    return '${title.substring(0, maxLength - 3)}...';
  }
  return title;
}

// Sorts games by the selected option 
// Takes in the games, filter type and if its ascending/descending?
List<dynamic> sortGames(List<dynamic> games, String sortBy, bool ascending) {
  switch (sortBy) {
    // Sorts alphabeticaly 
    case 'title':
      games.sort((a, b) {
        final comparison = (a['game_name'] as String).toLowerCase().compareTo((b['game_name'] as String).toLowerCase());
        return ascending ? comparison : -comparison;
      });
      break;

    // Sorts by release date 
    case 'release_date':
      games.sort((a, b) {
        int getYear(String? date) {
          if (date == null || date.isEmpty) {
            return -1; // Small year for null/invalid dates so they appear at the bottom
          }
          try {
            return int.parse(getYearFromDate(date));
          } catch (e) {
            return -1;
          }
        }

        final yearA = getYear(a['release_date']);
        final yearB = getYear(b['release_date']);

        int comparison = yearB.compareTo(yearA);
        return ascending ? comparison : -comparison;  // Reverse for descending
      });
      break;

  // Sorts by users rating
  case 'rating':
    games.sort((a, b) {
      final ratingA = a['rating'] is num ? a['rating'] : -1;
      final ratingB = b['rating'] is num ? b['rating'] : -1;

      // Adjust for -1 ratings, treating them as either infinity or negative infinity based on sorting order
      final adjustedRatingA = (ratingA == -1)
          ? (ascending ? double.negativeInfinity : double.infinity)
          : ratingA;
      final adjustedRatingB = (ratingB == -1)
          ? (ascending ? double.negativeInfinity : double.infinity)
          : ratingB;

      // First, sort by rating
      int comparison = adjustedRatingB.compareTo(adjustedRatingA);

      // If ratings are equal, sort alphabetically by title
      if (comparison == 0) {
        comparison = (a['game_name'] as String).toLowerCase().compareTo((b['game_name'] as String).toLowerCase());
      }

      return ascending ? comparison : -comparison;  // Reverse for descending
    });
    break;

    // Sorts by status (groups statuses together and sorts alphabetially within them)
    case 'status':
      games.sort((a, b) {
        final statusA = a['status'] ?? 0;
        final statusB = b['status'] ?? 0;

        final statusPriority = [1, 2, 0, 3];

        final priorityA = statusPriority.indexOf(statusA);
        final priorityB = statusPriority.indexOf(statusB);

        int comparison = priorityA.compareTo(priorityB);

        if (comparison == 0) {
          comparison = (a['game_name'] as String).toLowerCase().compareTo((b['game_name'] as String).toLowerCase());
        }

        return ascending ? comparison : -comparison;  // Reverse for descending
      });
      break;

    // Sorts by recently interacted with
    case 'most_recent':
      games.sort((a, b) {
        DateTime parseDate(String? date) {
          if (date == null || date.isEmpty) {
            return DateTime.fromMillisecondsSinceEpoch(0);
          }
          try {
            return DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parseUtc(date);
          } catch (e) {
            return DateTime.fromMillisecondsSinceEpoch(0);
          }
        }

        final dateA = parseDate(a['last_updated']);
        final dateB = parseDate(b['last_updated']);

        int comparison = dateB.compareTo(dateA); // Most recent first
        return ascending ? comparison : -comparison;  // Reverse for descending
      });
      break;

    // Sorts by how long each game is 
    case 'time_to_beat':
      games.sort((a, b) {
        final timeA = a['time_to_beat'] is num ? a['time_to_beat'] : double.infinity;
        final timeB = b['time_to_beat'] is num ? b['time_to_beat'] : double.infinity;

        // N/A values always sent to the bottom of the list
        final adjustedTimeA = (timeA == 0)
            ? (ascending ? double.infinity : double.negativeInfinity)
            : timeA;
        final adjustedTimeB = (timeB == 0)
            ? (ascending ? double.infinity : double.negativeInfinity)
            : timeB;

        int comparison = adjustedTimeA.compareTo(adjustedTimeB);

        // If comparison is 0, fall back to sorting by game name
        if (comparison == 0) {
          comparison = (a['game_name'] as String).toLowerCase().compareTo((b['game_name'] as String).toLowerCase());
        }

        return ascending ? comparison : -comparison;  // Reverse for descending
      });
      break;

    default:
      break;
  }
  return games;
}

// The List of games within the questlog page 
class GameList extends StatelessWidget {
  final List<dynamic> games;
  final Function onRefresh; // Callback to refresh the list

  const GameList({super.key, required this.games, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final containerHeight = availableHeight / 5;

        return ListView.builder(
          itemCount: games.length,
          itemBuilder: (context, index) {
            final Map<String, dynamic> game = games[index];


            // Status is stored as integers, so need to map to text names 
            const Map<int, String> statusMapping = {
              0: 'Want To Play',
              1: 'Playing',
              2: 'Completed',
              3: 'Dropped',
            };

           // Map the Icons that go next to the text 
           const Map<int, IconData> statusIconMapping = {
              0: FontAwesomeIcons.circlePlay,
              1: FontAwesomeIcons.gamepad, 
              2: FontAwesomeIcons.medal,  
              3: FontAwesomeIcons.trash,  
            };

            // Map colours for text and icons 
            const Map<int, Color> statusColorMapping = {
              0: Colors.orange,
              1: Color(0xFF36B6B0),
              2: Colors.green,
              3: Colors.red,
            };

            // Parse the json response into corresponding variables 
            final String title = game['game_name'] ?? 'Title';
            final String releaseDate = game['release_date'] != null ? getYearFromDate(game['release_date']) : 'Year';
            final double? timeToBeat = game['time_to_beat'] as double?;
            String formattedTimeToBeat = (timeToBeat != null) 
                ? timeToBeat.toInt().toString()  // Convert to int and remove decimal part
                : 'N/A';  // Fallback if timeToBeat is null
            final int statusNum = game['status'] ?? 0;
            final String statusText = statusMapping[statusNum] ?? 'Unknown';
            final Color statusColor = statusColorMapping[statusNum] ?? Colors.grey;
            final String rating = game['rating'] != null ? game['rating'].toString() : '-1';
            final String coverUrl = game['cover_url'] ?? '';

            // If tap anywhere on game entry other than the edit button, navigate to the game info page
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameInfoPage(
                      gameID: game['gameID'], 
                      gameHistoryID: game['game_historyID'],
                      gameStatus: game['status'],
                      gameRating: game['rating'],
                      coverUrl: coverUrl,
                      title: title,
                      dateEnd: game['date_end'],
                      dateStart: game['date_start'],
                    ),
                  ),
                ).then((_) {
                  onRefresh();
                });
              },
              // Container for each game 
              child: Container(
                height: containerHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? Color(0xFF403C3D) : Colors.white,
                  border: Border(
                    bottom: BorderSide(color: isDarkMode ? Color(0xFF5E5B5C) : Colors.grey[300]!, width: 2.0),
                  ),
                ),
                // Layout all the info for each game 
                child: Row(
                  children: [
                    // Using hero widget to fly cover between pages to keep users focus (really like this)
                    // But it makes handiling data annoyimg, api calls make page have to load and hero widget wont work
                    // Have to be conciousabout api calls, only do them when truly neccesary
                    Hero(
                      tag: 'cover_${game['gameID']}', //unique tag for each cover for the hero transition 
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4),
                        child: Container(
                          width: containerHeight * (264 / 374),
                          height: containerHeight,
                          color: Colors.transparent,
                          child: coverUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0), 
                                  child: Image.network(coverUrl, fit: BoxFit.cover),
                                )
                              : null,
                        ),
                      ),
                    ),
                    // Align everything else to the right of the cover image 
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0, bottom: 6.0, left: 3.0),
                      child: SizedBox(
                        width: constraints.maxWidth * 0.62,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Title, max length of 45, any longer has elpises 
                            Text(
                              getTruncatedString(title, 45),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white: Colors.black,
                              ),
                            ),
                            // Below title another row for time to beat and release date
                            Row(
                              children: [
                                // Release date
                                Text(
                                  releaseDate,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: isDarkMode ? Colors.white70: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Time to beat 
                               Text(
                                (formattedTimeToBeat == 'N/A' || formattedTimeToBeat == '0') 
                                    ? 'Time To Beat: N/A' 
                                    : 'Time To Beat: ${formattedTimeToBeat}h',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: isDarkMode ? Colors.white70: Colors.black87,
                                ),
                              ),
                              ],
                            ),
                            // Row under again with status and rating 
                            Row(
                              children: [
                                // Status Text
                                SizedBox(
                                  width: 160,
                                  child: Row(
                                    children: [
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(width: 10),
                                       // Status Icon
                                      Icon(
                                          statusIconMapping[statusNum],
                                          color: statusColor,
                                          size: 22, 
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Rating (only shows if user has assigned a rating to the game, -1 indicates no rating )
                                if (rating != '-1')
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: isDarkMode ? Colors.white: Colors.black,
                                        size: 35,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        rating,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Edit button, navigates to edit entry page 
                  Padding(
                      padding: EdgeInsets.only(left: 3.0, top: containerHeight * 0.25),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditEntryPage(
                                gameID: game['gameID'], 
                                gameHistoryID: game['game_historyID'],
                                gameStatus: game['status'],
                                gameRating: game['rating'],
                                coverUrl: coverUrl,
                                title: title,
                                dateEnd: game['date_end'],
                                dateStart: game['date_start'],
                                onSuccess: () {
                                  Navigator.pop(context);
                                  onRefresh();
                                },
                                onDeleteSuccess: (){
                                  Navigator.pop(context);
                                  onRefresh();
                                },
                                onFailure: (String errorMessage) {
                                  // Show an error message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(errorMessage)),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        // Using custom asset for edit and text with 'edit' underneath for clarity
                        child: Column(
                          children: [
                            Image.asset(
                              isDarkMode ? 'assets/edit_button.png' : 'assets/edit_button_dark.png',
                              width: constraints.maxWidth * 0.1,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 15,
                                color: isDarkMode ? Colors.white70: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}