import 'package:flutter/material.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';

// Takes user to Quest log page (essentially home page)
class HomeButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const HomeButton({super.key,required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Wrap the image with Transform.scale to shrink/grow when selected, visual feedback, swithches to slected png when clicked on too 
          Transform.scale(
            scale: isSelected ? 0.95 : 1.0, 
            child: Image.asset(
              isSelected
                ? (isDarkMode ? 'assets/home_selected.png' : 'assets/home_selected_dark.png')
                : (isDarkMode ? 'assets/home.png' : 'assets/home_dark.png'),
              width: 35,
              height: 35,
            ),
          ),
          const SizedBox(height: 3), 
          // Text under the button for clarity 
          Text(
            'Quest Log',
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