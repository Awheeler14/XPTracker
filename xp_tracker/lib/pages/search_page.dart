import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:xp_tracker/config.dart';
import 'package:xp_tracker/pages/game_info.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';

String getYearFromDate(String dateString) {
  final dateTime = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parse(dateString, true).toLocal();
  return DateFormat('yyyy').format(dateTime);
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _suggestions = [];
  bool _isLoading = false;
  bool _isRequestInProgress = false; // Flag to track request status
  Timer? _debounce;

  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  void showErrorMessage(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel(); // Cancel the debounce timer
    super.dispose();
  }

  // Fetch suggestions from the API
  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    if (_isRequestInProgress) return; // Dont send another request if one is already in progress

    setState(() {
      _isLoading = true;
      _isRequestInProgress = true; // Mark as request in progress
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/search_games'),
        body: jsonEncode({"game_name": query}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _suggestions = data;
        });
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    } catch (e) {
      setState(() {
        _suggestions = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isRequestInProgress = false; // Reset flag when the request is finished
      });
    }
  }

  // Debounce the search input
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF403C3D) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Color(0xFF635F60) : Colors.grey[300],
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search games...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: isDarkMode ? Colors.white70: Colors.black87,),
          ),
          style: TextStyle(color: isDarkMode ? Colors.white70: Colors.black87,),
          onChanged: _onSearchChanged, // Use debounced search
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white70: Colors.black87,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _buildSearchResults(context),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(isDarkMode ? Colors.white: Colors.black,),
            ),
            SizedBox(height: 30,),
            Text(
              "Searching...",
              style: TextStyle(
                color: isDarkMode ? Colors.white: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Center(
        child: Text(
          'No results found',
          style: TextStyle(
            color: isDarkMode ? Colors.white: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold
          ),
        ),
      );
    }

    // Calculate the available height for each result
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final availableHeight = screenHeight - appBarHeight;
    final resultHeight = (availableHeight / 5) * 0.8; // Reduce height by 20%

    // null check in results
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return Column(
          children: [
            if (index == 0) const SizedBox(height: 16),
            // Result item
            Material(
              color: Colors.transparent, // Prevents unwanted color changes
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameInfoPage(
                        gameID: suggestion['gameID'],
                        coverUrl: suggestion['cover_url'],
                        title: suggestion['game_name'],
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    height: resultHeight, // Set height for each result
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
                      children: [
                        // Cover image (90x128)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: (suggestion['cover_url'] != "https:NO URL" && suggestion['cover_url'].isNotEmpty)
                              ? Image.network(
                                  suggestion['cover_url'],
                                  width: 90,
                                  height: 128,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 90,
                                  height: 128,
                                  color: Colors.grey[700],
                                  child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                ),
                        ),
                        const SizedBox(width: 16),
                        // Game details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                suggestion['game_name'] ?? 'Unknown Title',
                                style: TextStyle(color: isDarkMode ? Colors.white: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (suggestion['release_date'] != null && suggestion['release_date'] is String)
                                    ? getYearFromDate(suggestion['release_date'])
                                    : 'Unknown Year',
                                style: TextStyle(color: isDarkMode ? Colors.white70: Colors.black87, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Add a divider between items
            if (index < _suggestions.length - 1)
              Divider(
                color: isDarkMode ? Color(0xFF5E5B5C) : Colors.grey[300],
                thickness: 1,
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
          ],
        );
      },
    );
  }
}