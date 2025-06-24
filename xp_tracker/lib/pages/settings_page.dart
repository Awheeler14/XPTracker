import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:xp_tracker/pages/login_page.dart';

// Settings page, its not gonna get any more complete than this in time
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF403C3D): Colors.white,
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
          // Toggle dark/light mode
          Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Dark Mode:',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(value),
                  activeColor: Colors.white,
                  activeTrackColor: Colors.green.shade700,
                  inactiveThumbColor: Colors.black,
                  inactiveTrackColor: Colors.grey,
                ),
              ],
            ),
          ),
          // Logs out user
          Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.green.shade700 : Colors.green,
              ),
              onPressed: () => _logout(context),
              child: Text(
                'Log Out',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),          
              ),
            )
          ),
        ],
      ),
    );
  }
}
