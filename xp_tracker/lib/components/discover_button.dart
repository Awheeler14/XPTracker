import 'package:flutter/material.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';


// Used to navigate to the discover page
class DiscoverButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const DiscoverButton({
    super.key,  
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return GestureDetector(
      // Navigate to the discover tab 
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            color: themeProvider.isDarkMode 
              ? (isSelected ? const Color(0xFF73C954) : Colors.white)
              : (isSelected ? Colors.green.shade700 : Colors.black), // Color based on selection
            size: isSelected ? 33.25 : 35, // Icon size
          ),
          const SizedBox(height: 3),
          Text(
            'Discover',
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