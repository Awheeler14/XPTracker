import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:xp_tracker/config.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';

// Notes page for each video game 
class NotesPage extends StatefulWidget {
  final int? gameHistoryID;

  const NotesPage({super.key, required this.gameHistoryID});

  @override
  NotesPageState createState() => NotesPageState();
}

class NotesPageState extends State<NotesPage> {
  String _note = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNote();
  }

  // Fecth the notes for the active game 
  Future<void> _fetchNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_game_notes?game_history_id=${widget.gameHistoryID}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isEmpty || data[0]['note'] == null || data[0]['note'].isEmpty) {
          setState(() {
            _note = '';
            _isLoading = false;
          });
        } else {
          setState(() {
            _note = data[0]['note'];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _note = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _note = '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF403C3D) : Colors.white,
      // Logo and back button in app bar 
      appBar: AppBar(
        backgroundColor: isDarkMode ? Color(0xFF635F60) : Colors.grey[300],
        automaticallyImplyLeading: true,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white: Colors.black,),
        title: Container(
          padding: const EdgeInsets.only(right: 0),
          child: Image.asset(
            'assets/Logo.png',
            height: 150,
            width: 150,
          ),
        ),
      ),
      // Doesnt let you type notes currently 
      // UGH this is not working, I'm leaving it like this
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hint text 
                  Text(
                    _note.isEmpty ? 'Start writing your notes...' : _note,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
