import 'package:flutter/material.dart';
import 'package:xp_tracker/config.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; 
import 'package:xp_tracker/components/rating_selector.dart';
import 'package:xp_tracker/components/start_end_dates.dart';
import 'package:xp_tracker/pages/notes_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';

// Takes in all neccesary information for editing the game detials
// Update parents if neccesary
// Not making an API call here so the Hero widget works 
// OnSuccess/failure handle updating the parent with the new edited details  
class EditEntryPage extends StatefulWidget {
  final int gameID;
  final int? gameHistoryID;
  final int? gameStatus;
  final int? gameRating;
  final String coverUrl;
  final String title;
  final String? dateEnd;
  final String? dateStart;
  final VoidCallback? onSuccess; 
  final VoidCallback? onDeleteSuccess;
  final Function(String)? onFailure; 

  const EditEntryPage({
    super.key,
    required this.gameID,
    this.gameHistoryID,
    required this.gameStatus,
    required this.gameRating,
    required this.coverUrl,
    required this.title,
    required this.dateEnd,
    required this.dateStart,
    this.onSuccess,
    this.onDeleteSuccess,
    this.onFailure, 
  });

  @override
  EditEntryPageState createState() => EditEntryPageState();
}

// Stores the initial status, rating and dates as well as the current ones. This allows to track if changes have been made
// By doing this, allows to enable the save button when changes are made
class EditEntryPageState extends State<EditEntryPage> {

  Future<bool> deleteGameFromHistory() async {
    final prefs = await SharedPreferences.getInstance();
                    int? userId = prefs.getInt('userId');
    final String url = '$baseUrl/delete_game_from_history?game_history_id=$gameHistoryID&user_id=$userId';

    try {
      final response = await http.delete(Uri.parse(url));

      // Only close if the deletion is successful
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  // Function to show the confirmation dialog for when the user removes a game from their log 
  void _showConfirmationDialog(BuildContext context) {
    showDialog(
    context: context,
    barrierDismissible: false, // Prevents closing the dialog by tapping outside
    builder: (BuildContext context) {
      final themeProvider = Provider.of<ThemeProvider>(context);
      final isDarkMode = themeProvider.isDarkMode;
      return AlertDialog(
        backgroundColor: isDarkMode ? Color(0xFF403C3D) : Colors.white,
        title: Text(
          'Delete Entry',
          style: TextStyle(
            fontSize: 20,
            color: isDarkMode ? Colors.white: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete this game from your quest log?',
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white: Colors.black,
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () async {
              final stopwatch = Stopwatch()..start(); 
              bool success = await deleteGameFromHistory();

              stopwatch.stop(); 
              //print('Delete game from history API call took ${stopwatch.elapsedMilliseconds} ms');

              // Access BuildContext safely after the async operation
              if (context.mounted) {
                if (success) {
                  // Close the dialog and page if deletion was successful
                  Navigator.of(context).pop();  
                  widget.onDeleteSuccess?.call(); 
                } else {
                  // Show a Snackbar for failure
                  Navigator.of(context).pop();  // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete game.',
                        style: TextStyle(color: isDarkMode ? Colors.white: Colors.black,),
                      ),
                      backgroundColor: isDarkMode ? Colors.red: Colors.red[800],
                    ),
                  );
                }
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDarkMode ? Colors.white: Colors.black,), 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), 
              ),
            ),
            child: Text(
              'Yes',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white: Colors.black,
              ),
            ),
          ),
          SizedBox(width: 3),
          OutlinedButton(
            onPressed: () {
              // Handle No action (close dialog)
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDarkMode ? Colors.white: Colors.black,), 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), 
              ),
            ),
            child: Text(
              'No',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white: Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  int selectedStatus = -1; 
  int initialStatus = -1;

  int selectedRating = 0;
  int initialRating = 0;

  String? initialStartDate;
  String? initialEndDate;

  String? selectedStartDate;
  String? selectedEndDate;

  int? gameHistoryID;

  // Mapping for status
  final Map<int, String> statusMapping = {
    0: 'Want To Play',
    1: 'Playing',
    2: 'Completed',
    3: 'Dropped',
  };

  final Map<int, IconData> statusIconMapping = {
    0: FontAwesomeIcons.circlePlay,
    1: FontAwesomeIcons.gamepad,
    2: FontAwesomeIcons.medal,
    3: FontAwesomeIcons.trash,
  };

  final Map<int, Color> statusColorMapping = {
    0: Colors.orange,
    1: Color(0xFF36B6B0),
    2: Colors.green,
    3: Colors.red,
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize start and end dates to null if they are not passed
    initialStartDate = formatDateString(widget.dateStart);
    initialEndDate = formatDateString(widget.dateEnd);

    // Format the start and end dates if they are not null
    selectedStartDate = formatDateString(widget.dateStart);
    selectedEndDate = formatDateString(widget.dateEnd);

    selectedStatus = widget.gameStatus ?? -1;
    initialStatus = widget.gameStatus ?? -1;

    selectedRating = widget.gameRating ?? 0;
    initialRating = widget.gameRating ?? 0;

    gameHistoryID = widget.gameHistoryID;
  }

  // No need to format if the date is null
  String? formatDateString(String? dateString) {
    if (dateString == null || dateString.trim().isEmpty) return null;
    try {
      DateTime parsedDate = DateFormat('EEE, dd MMM yyyy HH:mm:ss zzz').parse(dateString);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return null;
    }
  }



  // Check if status or rating has changed
  bool get hasStatusChanged => selectedStatus != initialStatus;
  bool get hasRatingChanged => selectedRating != initialRating;
  bool get hasStartDateChanged => selectedStartDate != initialStartDate;
  bool get hasEndDateChanged => selectedEndDate != initialEndDate;

  // Check if any value has changed to enable the save button 
  bool get hasChanges => hasStatusChanged || hasRatingChanged || hasStartDateChanged || hasEndDateChanged;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    // Get screenwidth for scaling of widgets
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF403C3D) : Colors.white,
      // App bar has back button, logo annd save button 
      appBar: AppBar(
        backgroundColor: isDarkMode ? Color(0xFF635F60) : Colors.grey[300],
        automaticallyImplyLeading: true,
        centerTitle: true,
        elevation: 0,
        // Logo position in centre
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/Logo.png',
              height: 150,
              width: 150,
            ),
          ],
        ),
        // Save button, only way to apply changes to the game history 
        // Probably should consolidate all the API calls into one, but not a priority 
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: Icon(
                Icons.save,
                // Grey out if no changes
                color: isDarkMode
                  ? (hasChanges && (gameHistoryID != null || hasStatusChanged != false) 
                      ? Colors.white 
                      : Colors.grey) // Slightly lighter than white
                  : (hasChanges && (gameHistoryID != null || hasStatusChanged != false) 
                      ? Colors.black 
                      : Colors.grey[500]), // Light grey for disabled 
                size: 28,
              ),
              onPressed: (hasChanges && (gameHistoryID != null || hasStatusChanged != false)) // Enable if any changes (when adding a game, a status must be selected)
                ? () async {
                    final prefs = await SharedPreferences.getInstance();
                    int? userId = prefs.getInt('userId');

                    try {
                      // Add Game to history if it does not yet exist 
                      if (gameHistoryID == null){
                        final stopwatch = Stopwatch()..start();
                        final addResponse = await http.post(
                          Uri.parse('$baseUrl/add_game_to_history'),
                          headers: {'Content-Type': 'application/json'},
                          body: json.encode({
                            "user_id": userId,  
                            "game_id": widget.gameID,
                            "status": selectedStatus,
                          }),
                        );
                        stopwatch.stop(); 
                        //print('Add game to history API call took ${stopwatch.elapsedMilliseconds} ms');
                        if (addResponse.statusCode == 200){
                          gameHistoryID = int.parse(addResponse.body);
                        }
                        else if (addResponse.statusCode != 200) {
                          widget.onFailure?.call('Failed to add game to history');
                          return;
                        }
                      }

                      // Update status if it changed
                      if (hasStatusChanged) {
                        final stopwatch = Stopwatch()..start();
                        final statusResponse = await http.post(
                          Uri.parse('$baseUrl/update_status'),
                          headers: {'Content-Type': 'application/json'},
                          body: json.encode({
                            "game_history_id": gameHistoryID,
                            "status": selectedStatus,
                          }),
                        );
                        stopwatch.stop(); 
                        //print('Edit game status API call took ${stopwatch.elapsedMilliseconds} ms');
                        if (statusResponse.statusCode != 200) {
                          widget.onFailure?.call('Failed to update status');
                          return;
                        }
                      }

                      // Update rating if it changed
                      if (hasRatingChanged) {
                        final ratingResponse = await http.post(
                          Uri.parse('$baseUrl/update_rating'),
                          headers: {'Content-Type': 'application/json'},
                          body: json.encode({
                            "game_history_id": gameHistoryID,
                            "rating": selectedRating,
                          }),
                        );
                        if (ratingResponse.statusCode != 200) {
                          widget.onFailure?.call('Failed to update rating');
                          return;
                        }
                      }

                      // Update start date if it changed
                      if (hasStartDateChanged) {
                        final startDateResponse = await http.post(
                          Uri.parse('$baseUrl/update_date'),
                          headers: {'Content-Type': 'application/json'},
                          body: json.encode({
                            "game_history_id": gameHistoryID,
                            "date": selectedStartDate,
                            "start_date": true,
                          }),
                        );
                        if (startDateResponse.statusCode != 200) {
                          widget.onFailure?.call('Failed to update start date');
                          return;
                        }
                      }

                      // Update end date if it changed
                      if (hasEndDateChanged) {
                        final endDateResponse = await http.post(
                          Uri.parse('$baseUrl/update_date'),
                          headers: {'Content-Type': 'application/json'},
                          body: json.encode({
                            "game_history_id": gameHistoryID,
                            "date": selectedEndDate,
                            "start_date": false,
                          }),
                        );
                        if (endDateResponse.statusCode != 200) {
                          widget.onFailure?.call('Failed to update end date');
                          return;
                        }
                      }

                      widget.onSuccess?.call(); // Trigger success if all updates are successful
                    } catch (e) {
                      widget.onFailure?.call('An error occurred: $e');
                    }
                  }
                : null,

            ),
          ),
        ],
        // Sets back arrow to white
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white: Colors.black,),
      ),
      // Body is scrollable 
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              // Game cover at top, in hero widget for nice transition, cover is gotten from coverURL
              child: Center(
                child: Hero(
                  tag: 'cover_${widget.gameID}',
                  child: SizedBox(
                    width: screenWidth / 2.8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0), 
                      child: Image.network(
                        widget.coverUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            // Title under the game 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Lines to help distinguish the different sections 
            Container(
              height: 2.0,
              color: isDarkMode ? Color(0xFF5E5B5C) : Colors.grey[300],
              width: screenWidth,
            ),
            // Title for the status 
            Padding(
              padding: const EdgeInsets.only(top:15.0, left: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Status:',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // First Row for status buttons
            // Using the _status button method to create the relevant buttons using the status mapping 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statusButton(context,1),
                  _statusButton(context,2),
                ],
              ),
            ),
            // Second Row for status buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statusButton(context,0),
                  _statusButton(context,3),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Container(
              height: 2.0,
              color: isDarkMode ? Color(0xFF5E5B5C) : Colors.grey[300],
              width: screenWidth,
            ),
            // Rating title 
            Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 15.0,),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Rating:',
                style: TextStyle(
                  color: isDarkMode ? Colors.white: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // The rating selector widget 
            Transform.translate(
              offset: const Offset(0, -15),
              child: RatingSelector(
                initialRating: selectedRating,
                onRatingSelected: (rating) {
                  setState(() {
                    selectedRating = rating;
                  });
                },
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                height: 2.0,
                color: isDarkMode ? Color(0xFF5E5B5C) : Colors.grey[300],
                width: screenWidth,
              ),
            ),
            // Date title 
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
              padding: const EdgeInsets.only(top: 15.0, left: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Dates:',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Date widget 
            Transform.translate(
              offset: const Offset(0, -35),
              child: StartEndDates(
                startDate: selectedStartDate,
                endDate: selectedEndDate,
                onStartDateChanged: (date) {
                  setState(() {
                    selectedStartDate = date;
                  });
                },
                onEndDateChanged: (date) {
                  setState(() {
                    selectedEndDate = date;
                  });
                },
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                height: 2.0,
                color: isDarkMode ? Color(0xFF5E5B5C) : Colors.grey[300],
                width: screenWidth,
              ),
            ),
            // Navigate to the notes page when the notes button is pressed 
            const SizedBox(height: 15),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotesPage(gameHistoryID: gameHistoryID),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: isDarkMode ? Colors.white70: Colors.black87,
                side: BorderSide(color: isDarkMode ? Colors.white70: Colors.black87, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 12),
              ),
              child: const Text(
                'Notes',
                style: TextStyle(fontSize: 30),
              ),
            ),
            const SizedBox(height: 25),
            Container(
              height: 2.0,
              color: isDarkMode ? Color(0xFF5E5B5C) : Colors.grey[300],
              width: screenWidth,
            ),
            const SizedBox(height: 15),
            if (gameHistoryID != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    FontAwesomeIcons.circleXmark,
                    color: isDarkMode ? Colors.red: Colors.red[800],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showConfirmationDialog(context),  // Show the dialog on tap
                    child: Text(
                      'Remove From Log',
                      style: TextStyle(
                        color: isDarkMode ? Colors.red: Colors.red[800],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (gameHistoryID != null) 
                Container(
                  height: 2.0,
                  color: isDarkMode ? Color(0xFF5E5B5C) : Colors.grey[300],
                  width: screenWidth,
                ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // Method to make the status buttons 
  // Takes the status mapping to put in the button 
  Widget _statusButton(BuildContext context, int index) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    double screenWidth = MediaQuery.of(context).size.width;

    return OutlinedButton(
      onPressed: () {
        setState(() {
          selectedStatus = index;
        });
      },
      // Button style
      style: OutlinedButton.styleFrom(
        minimumSize: Size(screenWidth * 0.45, 50),
        side: BorderSide(
          color: selectedStatus == index
            ? Colors.transparent
            : (isDarkMode ? Colors.white70 : Colors.black87), // Hide border when selected
          width: 2,
        ),
        backgroundColor: selectedStatus == index
            ? statusColorMapping[index] // Filled color for selected status
            : Colors.transparent,
      ),
      // Text and Icon for status
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            statusMapping[index]!,
            style: TextStyle(
              color: selectedStatus == index
                ? (isDarkMode ? Colors.white : Colors.black)
                : (isDarkMode ? Colors.white70 : Colors.black87),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8), 
          Icon(
            statusIconMapping[index],
            color: selectedStatus == index
                ? (isDarkMode ? Colors.white : Colors.black)
                : (isDarkMode ? Colors.white70 : Colors.black87),
            size: 20,
          ),
        ],
      ),
    );
  }
}
