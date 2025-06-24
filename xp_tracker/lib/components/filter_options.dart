import 'package:flutter/material.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';

// Handles all the options for the filters, active filter is highlighted, filters can be reversed
class FilterContainer extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;
  final bool timeToBeatAscending;
  final bool titleAscending;
  final bool lastUpdatedAscending;
  final bool ratingAscending;
  final bool releaseDateAscending;

  const FilterContainer({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.timeToBeatAscending,
    required this.titleAscending,
    required this.lastUpdatedAscending,
    required this.ratingAscending,
    required this.releaseDateAscending,
  });

  // Build the filter options based on passed in paramaters 
  Widget _buildOption(BuildContext context,String filter, String assetPath, String selectedAssetPath, {Widget? trailingIcon}) {
    bool isSelected = selectedFilter == filter;
    final themeProvider = Provider.of<ThemeProvider>(context);

    // For the gemstone selection symbol, switches between selected and unselected as neccesary 
    // And then the text is displayed after for the relevant filter 
    return GestureDetector(
      onTap: () => onFilterSelected(filter),
      child: Row(
        children: [
          Image.asset(
            isSelected ? selectedAssetPath : assetPath,
            height: 30,
            width: 30,
          ),
          const SizedBox(width: 10),
          Text(
            filter,
            style: TextStyle(
              color: themeProvider.isDarkMode 
              ? (isSelected ? const Color(0xFF73C954) : Colors.white)
              : (isSelected ? Colors.green.shade700 : Colors.black),
              fontSize: 18.0,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            trailingIcon,
          ],
        ],
      ),
    );
  }

  @override
  // Creates all the required filter options
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF403C3D): Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title for the filters 
            Text(
              'Filter By:',
              style: TextStyle(
                color: isDarkMode ? Colors.white: Colors.black,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
           const SizedBox(height: 10),
          _buildOption(
            context,
            'Alphabetical', 
            isDarkMode ? 'assets/filter_button.png' : 'assets/filter_button_dark.png',
            isDarkMode ? 'assets/filter_button_selected.png': 'assets/filter_button_selected_dark.png',
            trailingIcon: selectedFilter == 'Alphabetical'
                ? Icon( 
                    titleAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: const Color(0xFF73C954),
                    size: 18,
                  )
                : null,
          ),
          const SizedBox(height: 10),
          _buildOption(
            context,
            'Last Updated', 
            isDarkMode ? 'assets/filter_button.png' : 'assets/filter_button_dark.png',
            isDarkMode ? 'assets/filter_button_selected.png': 'assets/filter_button_selected_dark.png',
            trailingIcon: selectedFilter == 'Last Updated'
                ? Icon(
                    lastUpdatedAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: const Color(0xFF73C954),
                    size: 18,
                  )
                : null,
          ),
          const SizedBox(height: 10),
          _buildOption(
            context,
            'Rating', 
            isDarkMode ? 'assets/filter_button.png' : 'assets/filter_button_dark.png',
            isDarkMode ? 'assets/filter_button_selected.png': 'assets/filter_button_selected_dark.png',
            trailingIcon: selectedFilter == 'Rating'
                ? Icon(
                    ratingAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: const Color(0xFF73C954),
                    size: 18,
                  )
                : null,
          ),
          const SizedBox(height: 10),
          _buildOption(
            context,
            'Release Date', 
            isDarkMode ? 'assets/filter_button.png' : 'assets/filter_button_dark.png',
            isDarkMode ? 'assets/filter_button_selected.png': 'assets/filter_button_selected_dark.png',
            trailingIcon: selectedFilter == 'Release Date'
                ? Icon(
                    releaseDateAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: const Color(0xFF73C954),
                    size: 18,
                  )
                : null,
          ),
          const SizedBox(height: 10),
          _buildOption(
            context,
            'Status', 
            isDarkMode ? 'assets/filter_button.png' : 'assets/filter_button_dark.png',
            isDarkMode ? 'assets/filter_button_selected.png': 'assets/filter_button_selected_dark.png',
          ),
          const SizedBox(height: 10),
          _buildOption(
            context,
            'Time To Beat',
            isDarkMode ? 'assets/filter_button.png' : 'assets/filter_button_dark.png',
            isDarkMode ? 'assets/filter_button_selected.png': 'assets/filter_button_selected_dark.png',
            trailingIcon: selectedFilter == 'Time To Beat'
                ? Icon(
                    timeToBeatAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: const Color(0xFF73C954),
                    size: 18,
                  )
                : null,
            ),
          ],
        ),
      ),
    );
  }
}