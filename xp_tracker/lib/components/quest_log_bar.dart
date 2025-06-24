import 'package:flutter/material.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';


// The bar at the top to select games only in a certain status 
// options is all the options at the top
// selectedIndex indicates the option that is selexted
// onOptionSelected tells quest log which games to display based on status 

class QuestLogBar extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final Function(int) onOptionSelected;

  const QuestLogBar({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return Container(
      width: double.infinity,
      color: isDarkMode ? Color(0xFF635F60) : Colors.grey[300], 
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        // Takes the list to create the options at the top 
        children: List.generate(options.length, (index) {

          return GestureDetector(
            onTap: () {
              onOptionSelected(index);
            },
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Text(
                  options[index],
                  style: TextStyle(
                    color: themeProvider.isDarkMode 
                        ? (selectedIndex == index ? Color(0xFF73C954) : Colors.white) // Dark mode settings
                        : (selectedIndex == index ? Colors.green.shade700 : Colors.black), // Light mode settings
                    fontSize: 16,
                  ),
                ),
                // Animated green bar underneath the text to help visualise whats selected 
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300), 
                  curve: Curves.easeInOut, 
                  bottom: selectedIndex == index ? 0 : -6.0, 
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300), 
                    width: options[index].length * 8.0, 
                    height: 3.0, 
                    color: isDarkMode? Color(0xFF73C954): Colors.green.shade700
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}