import 'package:flutter/material.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';


// the container for the history details that shows up when clicking on the number of entries
class EntryInfoContainer extends StatelessWidget {
  final double averageRating;
  final Map<int, int> statusCounts;

  const EntryInfoContainer({super.key, required this.averageRating, required this.statusCounts});

  @override
  Widget build(BuildContext context) {
    int totalEntries = statusCounts.values.fold(0, (sum, count) => sum + count);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Calculate the available width for the bar (half of screen minus the width for the text)
    double textWidth = 120.0; // Fixed width for the text
    double availableWidth = MediaQuery.of(context).size.width * 0.5 - textWidth;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF403C3D): Colors.white,
        ),
        height: 250, 
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(left: 5.0, top: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title for Status Distribution
              Text(
                'Status Distribution:',
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 5,),
              // Bar chart with labels and numbers
              totalEntries > 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBarWithText(statusCounts[1] ?? 0, totalEntries, Color(0xFF36B6B0), 'Playing', availableWidth),
                        _buildStatusBarWithText(statusCounts[2] ?? 0, totalEntries, Colors.green, 'Completed', availableWidth),
                        _buildStatusBarWithText(statusCounts[0] ?? 0, totalEntries, Colors.orange, 'Want To Play', availableWidth),
                        _buildStatusBarWithText(statusCounts[3] ?? 0, totalEntries, Colors.red, 'Dropped', availableWidth),
                      ],
                    )
                  : Container(), // Empty container if no data
              const SizedBox(height: 5,),
              // Average rating calced from users average rating of all currently displayed games 
              Text(
                'Average Rating: ${averageRating.toStringAsFixed(1)}',
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusBarWithText(int count, int totalEntries, Color color, String label, double availableWidth) {
    // Calculate the width of the bar as a percentage of the total entries
    double width = totalEntries > 0 ? (count / totalEntries) * availableWidth : 0;

    // Ensures no overflow for width
    double maxWidth = availableWidth;
    width = width > maxWidth ? maxWidth : width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120.0, // Fixed width for the text
            child: Text(
              '$label: $count',
              style: TextStyle(
                color: color,
                fontSize: 16.0, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 5),
          // Bar Container that enforces width proportional to the count (so the bars correspond to the number of entries)
          Container(
            width: width, 
            height: 15,
            color: color,
          ),
        ],
      ),
    );
  }
}
