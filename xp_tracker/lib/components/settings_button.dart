import 'package:flutter/material.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';

// Button on the bottom bar to navigate to the settings page
class SettingsButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const SettingsButton({super.key,required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // change icon and text colour if selected 
        children: [
          Icon(
            Icons.settings, 
            color: themeProvider.isDarkMode 
              ? (isSelected ? const Color(0xFF73C954) : Colors.white)
              : (isSelected ? Colors.green.shade700 : Colors.black),
            size: isSelected ? 33.25 : 35, 
          ),
          const SizedBox(height: 3),
          Text(
            'Settings',
            style: TextStyle(
              color: themeProvider.isDarkMode 
              ? (isSelected ? const Color(0xFF73C954) : Colors.white)
              : (isSelected ? Colors.green.shade700 : Colors.black), 
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}