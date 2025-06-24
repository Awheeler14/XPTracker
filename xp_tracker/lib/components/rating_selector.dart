import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';

// Rating selecter for the edit entry page
// Initial rating tells which option to display as selected
// When a rating is selected it is passed back to the edit page, if it is different to the initial rating passed in 
class RatingSelector extends StatefulWidget {
  final Function(int) onRatingSelected;
  final int initialRating;

  const RatingSelector({
    super.key,
    required this.onRatingSelected,
    required this.initialRating,
  });

  @override
  RatingSelectorState createState() => RatingSelectorState();
}

// Acts as a scrollable list, options in circles, one under triangle is selection
class RatingSelectorState extends State<RatingSelector> {
  late int selectedRating;
  final PageController _pageController = PageController(viewportFraction: 0.15);

  @override
  void initState() {
    super.initState();
    selectedRating = widget.initialRating;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Jump to the selected rating (index 1 = rating 10, index 10 = rating 1)
      // Special case for 0 rating (No Entry)
      _pageController.jumpToPage(selectedRating == 0 ? 0 : 11 - selectedRating);
    });
  }

  // Assigns the colour to the rating circle based on where it is in the scale. 10 is green, 1 is red 
  Color getRatingColor(int rating) {
    if (rating == 0) return Color(0xFFA5A7AC); // No entry color
    double percentage = (10 - rating) / 9;
    return Color.lerp(Colors.green, Colors.red, percentage)!;
  }

  // Makes the no rating appear on the left rather than at the end of the list 
  // Passes back the selected rating
  void _handleRatingChange(int pageIndex) {
    // Map index 0 to "No Entry", otherwise reverse the mapping
    int rating = (pageIndex == 0) ? 0 : 11 - pageIndex;
    HapticFeedback.selectionClick();
    setState(() {
      selectedRating = rating;
    });
    widget.onRatingSelected(rating);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return Column(
      // Triangle above the rating selector to help visualise the selected option 
      children: [
        Transform.translate(
          offset: const Offset(0, -20), // Move the triangle higher because it's too low
          child: Icon(
            Icons.arrow_drop_down,
            color: getRatingColor(selectedRating), 
            size: 50,
          ),
        ),
        SizedBox(
          height: 75,
          child: Transform.translate(
            offset: const Offset(0, -30),
            child: PageView.builder(
              controller: _pageController,
              itemCount: 11, // 0 for "No Entry" + 10 ratings
              onPageChanged: _handleRatingChange,
              itemBuilder: (context, index) {
                // Map index 0 to "No Entry", otherwise reverse the mapping
                final rating = (index == 0) ? 0 : 11 - index;
                final isSelected = rating == selectedRating;
                return Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    // Change the size of the selected rating for better visualization 
                    // Rating in a circlem colour changes based on if the rating is selected
                    height: isSelected ? 65 : 55,
                    width: isSelected ? 65 : 55,
                    decoration: BoxDecoration(
                      color: isSelected ? getRatingColor(rating) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                          ? Colors.transparent
                          : (isDarkMode ? Colors.white70 : Colors.black87),
                        width: 2,
                      ),
                    ),
                    // Rating number in the circle
                    child: Center(
                      child: rating == 0
                          ? Icon(
                              Icons.block,
                              // White/Black when selected to stand out
                              color: isSelected
                                ? (isDarkMode ? Colors.white : Colors.black)
                                : (isDarkMode ? Colors.white70 : Colors.black87),
                              size: 28,
                            )
                          : Text(
                              '$rating',
                              style: TextStyle(
                                color: isSelected
                                  ? (isDarkMode ? Colors.white : Colors.black)
                                  : (isDarkMode ? Colors.white70 : Colors.black87),
                                fontSize: isSelected ? 26 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

