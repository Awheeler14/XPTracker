import 'package:flutter/material.dart';
import 'package:xp_tracker/config.dart';
import 'package:xp_tracker/pages/search_page.dart';
import 'package:xp_tracker/pages/game_info.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';


// Discover page for application 
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  DiscoverPageState createState() => DiscoverPageState();
}

class DiscoverPageState extends State<DiscoverPage> {
  double containerWidth = 264 / 2.9;
  double containerHeight = 374 / 2.9;

  bool isLoading = true;
  List<dynamic> forYouGames = [];
  List<dynamic> newReleases = [];
  Timer? pollingTimer;

  @override
  void initState() {
    super.initState();
    fetchRecommendations();
  }

  @override
  void dispose() {
    pollingTimer?.cancel();
    super.dispose();
  }


  // Attempt to fetch reccomendations
  Future<void> fetchRecommendations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    final url = '$baseUrl/fetch_reccomendations?user_id=$userId';
    final response = await http.get(Uri.parse(url));

    // If data is ready, store it in appropriate scrollable lists and cancel polling timer 
    // Else, set polling timer to 3 seconds, to retry call when it runs out
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        forYouGames = data['recommendations'];
        newReleases = data['recent'];
        isLoading = false;
      });
      pollingTimer?.cancel(); // Stop polling
    } else if (response.statusCode == 423) {
      // Recommendations not ready yet
      if (pollingTimer == null || !pollingTimer!.isActive) {
        pollingTimer = Timer.periodic(Duration(seconds: 2), (_) {
          fetchRecommendations();
        });
      }
    } 
    // else {
    //   print("Error fetching recommendations: ${response.statusCode}");
    // }
  }
      

  // Builds grid of suggestions
  Widget buildGameGrid(List<dynamic> items, bool isLoading, BuildContext context, bool isDarkMode) {
    double screenWidth = MediaQuery.of(context).size.width;
    double imageWidth = (screenWidth / 3) - 10;
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,  
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              Text(
                "Loading recommendations...",
                style: TextStyle(
                  fontSize: 24,  
                  fontWeight: FontWeight.bold,  
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),  
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? Colors.white70 : Colors.black87,  
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: GridView.builder(
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.59,
        ),
        itemBuilder: (context, index) {
          final game = items[index];
          return GestureDetector(
            onTap: () {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    game['cover_url'] ?? '',
                    fit: BoxFit.cover,
                    width: imageWidth,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: imageWidth,
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.broken_image, color: Colors.white),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  game['game_name'] ?? 'Game Title',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Builds the tabs to swap between 
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDarkMode ? Color(0xFF403C3D) : Colors.white,
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            SizedBox(
              height: 47,
              child: Container(
                width: double.infinity,
                color: isDarkMode ? Color(0xFF635F60) : Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
              // Search bar 
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: isDarkMode ? Color(0xFF635F60) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: isDarkMode ? Colors.white70 : Colors.black87),
                    SizedBox(width: 8),
                    Text('Search games...',
                        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
                  ],
                ),
              ),
            ),
             const SizedBox(height: 5),
            Theme(
              data: Theme.of(context).copyWith(
                splashFactory: NoSplash.splashFactory,          // no ripple 
                splashColor: Colors.transparent,                // Just in case
                highlightColor: Colors.transparent,             // Removes tap-down overlay
              ),
              child: TabBar(
                labelColor: isDarkMode ? const Color(0xFF73C954) : Colors.green.shade700,
                unselectedLabelColor: isDarkMode ? Colors.white : Colors.black,
                indicatorColor: isDarkMode ? const Color(0xFF73C954) : Colors.green.shade700,
                tabs: const [
                  Tab(text: 'For You'),
                  Tab(text: 'New Releases'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                // Build reccomendations
                children: [
                  buildGameGrid(forYouGames, isLoading, context, isDarkMode),
                  buildGameGrid(newReleases, isLoading, context, isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}