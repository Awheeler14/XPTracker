import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xp_tracker/config.dart';
import 'package:xp_tracker/components/discover_button.dart';
import 'package:xp_tracker/components/home_button.dart';
import 'package:xp_tracker/components/settings_button.dart';
import 'package:xp_tracker/pages/quest_log_page.dart';
import 'package:xp_tracker/pages/discover_page.dart';
import 'package:xp_tracker/pages/settings_page.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';

// Home page for the app, contains quest log, discover and settings
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentPageIndex = 0;
  final PageController _pageController = PageController();

  // User data default values 
  String username = '';
  String profilePictureUrl = '';
  int? userId;

  @override
  void initState() {
    super.initState();
    // Retrieve userId from SharedPreferences and fetch user data
    _getUserIdFromPreferences();
  }

  // Fetch the userId from SharedPreferences (stored in here because needed in multiple places, also allows app to stay logged in)
  Future<void> _getUserIdFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId');
    });

    if (userId != null) {
      fetchUserData();
    } 
  }

  // Fetch user data (username and profile picture) from API
  Future<void> fetchUserData() async {
    if (userId == null) return;

    final response = await http.get(
      Uri.parse('$baseUrl/get_user?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        username = data['username'];
        profilePictureUrl = data['profile_picture'];
      });
    } 
  }

  // Handle bottom navigation taps by animating the PageView, looks like its sliding
  void _onNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Stack(
            alignment: Alignment.center, 
            children: [
              // Profile Picture (aligned to the left)
              Align(
                alignment: Alignment.centerLeft, // Force the profile picture to the left
                child: profilePictureUrl.isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(profilePictureUrl),
                        radius: 20,
                      )
                    : const CircleAvatar(
                        backgroundColor: Colors.grey,
                        radius: 20,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
              ),

              // Logo (centered)
              Image.asset(
                'assets/Logo.png',
                height: 150,
                width: 150,
              ),
            ],
          ),
        ),
        backgroundColor: isDarkMode ? Color(0xFF635F60) : Colors.grey[300], 
        centerTitle: true,
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator()) // Show a loading indicator while fetching data
          : PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              children: const [
                QuestLogPage(),
                DiscoverPage(),
                SettingsPage(),
              ],
            ),
      backgroundColor: isDarkMode ?  Color(0xFF403C3D) : Colors.white, 
      bottomNavigationBar: BottomAppBar(
        color: isDarkMode ? Color(0xFF635F60) : Colors.grey[300], 
        child: Padding(
          padding: const EdgeInsets.all(0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // navigate betwem the pages, can tap buttons or swipe 
              HomeButton(
                isSelected: _currentPageIndex == 0,
                onTap: () => _onNavTapped(0),
              ),
              DiscoverButton(
                isSelected: _currentPageIndex == 1,
                onTap: () => _onNavTapped(1),
              ),
              SettingsButton(
                isSelected: _currentPageIndex == 2,
                onTap: () => _onNavTapped(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
