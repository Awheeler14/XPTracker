import 'package:flutter/material.dart';
import 'package:xp_tracker/config.dart';
import 'package:xp_tracker/components/quest_log_bar.dart';
import 'package:xp_tracker/components/filter_and_entry_count.dart';
import 'package:xp_tracker/components/game_list.dart';
import 'package:xp_tracker/components/filter_options.dart';
import 'package:xp_tracker/components/entry_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuestLogPage extends StatefulWidget {
  const QuestLogPage({super.key});

  @override
  QuestLogPageState createState() => QuestLogPageState();
}

// Quest log page, contains the Status bar, the filter/entries bar and the games list 
class QuestLogPageState extends State<QuestLogPage> with TickerProviderStateMixin {
  int selectedIndex = 0;
  final List<String> options = ['All', 'Playing', 'Completed', 'Want to play', 'Dropped'];
  // number of entries 
  int totalEntries = 0;
  // are the filter/entry boxes visible 
  bool isFilterVisible = false;
  bool isEntryInfoVisible = false;
  // Default filter is alphabetical 
  String selectedFilter = 'Alphabetical';
  late List<dynamic> games = [];
  bool isLoading = true;
  String? errorMessage;

  // Animations for drop downs for filter and entries info 
  late AnimationController _filterAnimationController;
  late AnimationController _entryInfoAnimationController;

  late Animation<double> _filterHeightAnimation;
  late Animation<double> _entryInfoHeightAnimation;

  double averageRating = 0.0;
  Map<int, int> statusCounts = {0: 0, 1: 0, 2: 0, 3: 0};

  // Indciates if filter should be ascending or descending 
  bool timeToBeatAscending = true;
  bool titleAscending = true;
  bool lastUpdatedAscending = true;
  bool ratingAscending = true;
  bool releaseDateAscending = true;

  @override
  void initState() {
    super.initState();
    _loadFilterPreference();

    // Animation controllers for the dropdowns 
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _entryInfoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _filterHeightAnimation = Tween<double>(
      begin: 0,
      end: 300,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    ));

    _entryInfoHeightAnimation = Tween<double>(
      begin: 0,
      end: 250,
    ).animate(CurvedAnimation(
      parent: _entryInfoAnimationController,
      curve: Curves.easeInOut,
    ));

    // Gets the game history for the games list 
    fetchGameHistory();
  }

  // Sets the selected filter 
  Future<void> _loadFilterPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedFilter = prefs.getString('selectedFilter') ?? 'Alphabetical';
    });
  }

  // Fetches all the games the user has in their log 
  Future<void> fetchGameHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final url = '$baseUrl/get_user_game_history?user_id=$userId';

      final stopwatch = Stopwatch()..start();

      final response = await http.get(Uri.parse(url));

      stopwatch.stop();  // stop the timer after the response is received
      //print('Fetch history nAPI call took ${stopwatch.elapsedMilliseconds} ms\n\\n');
      if (response.statusCode == 200) {
        final List<dynamic> fetchedGames = jsonDecode(response.body);
        setState(() {
          games = sortGames(fetchedGames, mapFilterToKey(selectedFilter),timeToBeatAscending);
          applyStatusFilter(selectedIndex);
          totalEntries = games.length;
          averageRating = calculateAverageRating(games); // update rating for entries info
          //calculateStatusCounts(fetchedGames);  // updates status counts for entries info
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load game history');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // Calcs average rating for the games
  double calculateAverageRating(List<dynamic> games) {
    if (games.isEmpty) return 0.0;

    double totalRating = 0;
    int ratedGamesCount = 0;

    for (var game in games) {
      if (game['rating'] != null) {
        totalRating += game['rating'];
        ratedGamesCount++;
      }
    }

    return ratedGamesCount == 0 ? 0.0 : totalRating / ratedGamesCount;
  }

  // Calculates the number of each statuses there are 
  void calculateStatusCounts(List<dynamic> games) {
    Map<int, int> updatedStatusCounts = {0: 0, 1: 0, 2: 0, 3: 0};

    for (var game in games) {
      int status = game['status'];
      if (updatedStatusCounts.containsKey(status)) {
        updatedStatusCounts[status] = updatedStatusCounts[status]! + 1;
      }
    }

    setState(() {
      statusCounts = updatedStatusCounts;  
    });
  }

  // Applies the filter to the games list before its passed into the games list widget 
  void applyStatusFilter(int index) {
    List<dynamic> filteredGames;

    if (index == 0) {
      filteredGames = games;
    } else {
      int statusFilter = switch (index) {
        1 => 1,
        2 => 2,
        3 => 0,
        _ => 3,
      };

      // Only apply to currently displayed games 
      filteredGames = games.where((game) => game['status'] == statusFilter).toList();
    }

    // Calculates all needed information 
    setState(() {
      games = filteredGames;
      totalEntries = games.length;
      averageRating = calculateAverageRating(games);
      calculateStatusCounts(games);
    });
  }

  // toggles filter dropdown being visibile or not 
  void toggleFilterVisibility() {
    setState(() {
      if (isEntryInfoVisible) {
        isEntryInfoVisible = false;
        _entryInfoAnimationController.reverse();
      }
      isFilterVisible = !isFilterVisible;
      isFilterVisible ? _filterAnimationController.forward() : _filterAnimationController.reverse();
    });
  }

  // toggles entries dropdown being visibile or not 
  void toggleEntryInfoVisibility() {
    setState(() {
      if (isFilterVisible) {
        isFilterVisible = false;
        _filterAnimationController.reverse();
      }
      isEntryInfoVisible = !isEntryInfoVisible;
      isEntryInfoVisible ? _entryInfoAnimationController.forward() : _entryInfoAnimationController.reverse();
    });
  }

  // Appply filter based on what was selected + ascending or descending 
 void onFilterSelected(String filter) {
  setState(() {
    if (filter == 'Time To Beat') {
      if (selectedFilter != 'Time To Beat') {
        timeToBeatAscending = true;
      } else {
        timeToBeatAscending = !timeToBeatAscending;
      }
    } else if (filter == 'Alphabetical') {
      if (selectedFilter != 'Alphabetical') {
        titleAscending = true;
      } else {
        titleAscending = !titleAscending;
      }
    } else if (filter == 'Last Updated') {
      if (selectedFilter != 'Last Updated') {
        lastUpdatedAscending = true;
      } else {
        lastUpdatedAscending = !lastUpdatedAscending;
      }
    } else if (filter == 'Rating') {
      if (selectedFilter != 'Rating') {
        ratingAscending = true;
      } else {
        ratingAscending = !ratingAscending;
      }
    } else if (filter == 'Release Date') {
      if (selectedFilter != 'Release Date') {
        releaseDateAscending = true;
      } else {
        releaseDateAscending = !releaseDateAscending;
      }
    } else {
      timeToBeatAscending = true;
      titleAscending = true;
      lastUpdatedAscending = true;
      ratingAscending = true;
      releaseDateAscending = true;
    }

    selectedFilter = filter;

    // Set the selected filter in shared prefrences 
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('selectedFilter', filter);
    });

    games = sortGames(games, mapFilterToKey(filter), _getSortOrder(filter));
    });
  }

  // Return if filter is ascending or descending 
  bool _getSortOrder(String filter) {
    if (filter == 'Time To Beat') {
      return timeToBeatAscending;
    } else if (filter == 'Alphabetical') {
      return titleAscending;
    } else if (filter == 'Last Updated') {
      return lastUpdatedAscending;
    } else if (filter == 'Rating') {
      return ratingAscending;
    } else if (filter == 'Release Date') {
      return releaseDateAscending;
    }
    return true;  // Default sorting order is ascending
  }

  // Map filter names to selected options 
  String mapFilterToKey(String filter) {
    switch (filter) {
      case 'Alphabetical':
        return 'title';
      case 'Release Date':
        return 'release_date';
      case 'Rating':
        return 'rating';
      case 'Status':
        return 'status';
      case 'Last Updated':
        return 'most_recent';
      case 'Time To Beat':
        return 'time_to_beat';
      default:
        return 'title';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Show status options bar at top 
            QuestLogBar(
              options: options,
              selectedIndex: selectedIndex,
              onOptionSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
                fetchGameHistory();
              },
            ),
            // Filter bar underneath it 
            FilterBar(
              totalEntries: totalEntries,
              onFilterToggle: toggleFilterVisibility,
              onEntryInfoToggle: toggleEntryInfoVisibility,
            ),
            // Games list underneatht top bars 
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(child: Text('Error: $errorMessage'))
                      : GameList(
                          games: games,
                          onRefresh: fetchGameHistory
                        ),
            ),
          ],
        ),
        // Show filter/entry dropdown and dim down background if they are shown to draw focus 
        // Only one can be shown at a time 
        if (isFilterVisible || isEntryInfoVisible)
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isFilterVisible = false;
                  isEntryInfoVisible = false;
                  _filterAnimationController.reverse();
                  _entryInfoAnimationController.reverse();
                });
              },
              child: Container(
                color: const Color.fromRGBO(0, 0, 0, 0.5),
              ),
            ),
          ),
        // Show filter dropdown 
        if (isFilterVisible)
          Positioned(
            top: 80,
            left: MediaQuery.of(context).size.width * 0.5,
            right: 0,
            child: AnimatedBuilder(
              animation: _filterHeightAnimation,
              builder: (context, child) {
                return SizedBox(
                  height: _filterHeightAnimation.value,
                  child: FilterContainer(
                    selectedFilter: selectedFilter,
                    onFilterSelected: onFilterSelected,
                    timeToBeatAscending: timeToBeatAscending,
                    titleAscending: titleAscending,
                    lastUpdatedAscending: lastUpdatedAscending,
                    ratingAscending: ratingAscending,
                    releaseDateAscending: releaseDateAscending,
                  ),
                );
              },
            ),
          ),
        // show entry dropdown 
        if (isEntryInfoVisible)
          Positioned(
            top: 80,
            left: 0,
            right: MediaQuery.of(context).size.width * 0.4,
            child: AnimatedBuilder(
              animation: _entryInfoHeightAnimation,
              builder: (context, child) {
                return SizedBox(
                  height: _entryInfoHeightAnimation.value,
                  child: EntryInfoContainer(
                    averageRating: averageRating,
                    statusCounts: statusCounts,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _entryInfoAnimationController.dispose();
    super.dispose();
  }
}