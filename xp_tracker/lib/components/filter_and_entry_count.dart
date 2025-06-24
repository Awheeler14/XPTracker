import 'package:flutter/material.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';


// The bar that shows up on top of quest log page and contains the filter options and entry count 
// Colour matches the app bar so blends in 
class FilterBar extends StatelessWidget {
  final int totalEntries;
  final VoidCallback onFilterToggle;
  final VoidCallback onEntryInfoToggle;

  const FilterBar({
    super.key,
    required this.totalEntries,
    required this.onFilterToggle,
    required this.onEntryInfoToggle,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return Container(
      height: 40,
      color: isDarkMode ? Color(0xFF403C3D): Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Entries on the left of the bar 
          GestureDetector(
            onTap: onEntryInfoToggle,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Icon(
                    Icons.videogame_asset,
                    color: isDarkMode ? Colors.lightBlue: Colors.blue[700],
                    size: 24.0,
                  ),
                ),
                Text(
                  '$totalEntries entries',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: isDarkMode ? Colors.lightBlue: Colors.blue[700]
                  ),
                ),
              ],
            ),
          ),
          // Filter button 
          GestureDetector(
            onTap: onFilterToggle,
            child: Row(
              children: [
                Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: isDarkMode ? Colors.lightBlue: Colors.blue[700]
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 6.0),
                  child: Icon(
                    Icons.filter_list,
                    color: isDarkMode ? Colors.lightBlue: Colors.blue[700],
                    size: 24.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}