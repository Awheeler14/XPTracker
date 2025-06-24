import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:xp_tracker/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xp_tracker/components/my_textfield.dart';
import 'package:xp_tracker/components/sign_in_button.dart';
import 'package:xp_tracker/pages/home.dart'; 
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';

// allows user to login
// NEED TO SET UP CREATING A USER
// FORGOT PASSWORD IS DISPLAYED BUT WILL NOT WORK IN THE SCOPE OF THIS PROJECT AS EMAIL VERIFICATION REQUIRES A WEB DOMAIN AND SOME OTHER 
// STUFF I DO NOT HAVE ACCESS TOO
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  // text editing controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // state to toggle password visibility
  bool _isPasswordVisible = false;

  // sign user in method
  // Compares password to one stored in db 
  Future<void> signUserIn(BuildContext context) async {
    String username = usernameController.text;
    String password = passwordController.text;

    final stopwatch = Stopwatch()..start();

    var url = Uri.parse("$baseUrl/check_passwords_match");
    
    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_name": username,
          "input_password": password,
        }),
        
      );
      if (response.statusCode == 200) {
        // Success case: Parse the JSON response
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          // User login successful, store the userId
          int userId = jsonResponse['user_id'];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setInt('userId', userId);

          // Only use context if widget is still mounted (guarding with a mounted check)
          if (!context.mounted) return;

          // Navigate to HomePage after a successful login
          Navigator.pushReplacement(
            context,
            _createSlideTransitionRoute(userId),
          );
        } 
      } else if (response.statusCode == 401) {
        // Unauthorized case: Handle 401 specifically
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid username or password',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (response.statusCode == 400) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please provide both a username and password',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Handle other errors (non-200, non-401 status codes)
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${response.statusCode}',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      stopwatch.stop();  
      //print('API to login call took ${stopwatch.elapsedMilliseconds} ms');
    } 
    catch (e) {
      // Handle connection errors
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to connect to the server: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // lets home page slide in, nicer transition 
  Route _createSlideTransitionRoute(int userId) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
    transitionDuration: const Duration(milliseconds: 500),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0); // Start the slide from the bottom
      const end = Offset.zero; 
      const curve = Curves.easeInOut; 

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return Scaffold(
      // Keyboard slides up over app 
      resizeToAvoidBottomInset: false,
      backgroundColor: isDarkMode ? Color(0xFF403C3D) : Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              // LOGO at top of screen 
              Image.asset('assets/Logo.png', width: 300, height: 200),
              // Welcome message 
              Text(
                'Welcome To XP Tracker!',
                style: TextStyle(color: isDarkMode ? Color(0xFFB1B6BB) : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 25),
              // Username field 
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Text(
                    'Username:',
                    style: TextStyle(color: isDarkMode ? Color(0xFFB1B6BB) : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              MyTextfield(
                controller: usernameController,
                hintText: 'Username',
                obscureText: false,
              ),
              // Password field 
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Text(
                    'Password:',
                    style: TextStyle(color: isDarkMode ? Color(0xFFB1B6BB) : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              MyTextfield(
                controller: passwordController,
                hintText: 'Password',
                obscureText: !_isPasswordVisible, // Toggle visibility
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 25.0),
                        // Allows user to toggle text visibility on the password 
                        child: Text(
                          'Show Password?',
                          style: TextStyle(color: isDarkMode ? Color(0xFFB1B6BB) : Colors.black87, fontWeight: FontWeight.bold ,fontSize: 16),
                        ),
                      ),
                      Checkbox(
                        side: BorderSide(color: isDarkMode ? Color(0xFFB1B6BB) : Colors.black87),
                        value: _isPasswordVisible,
                        onChanged: (bool? value) {
                          setState(() {
                            _isPasswordVisible = value!;
                          });
                        },
                        activeColor: isDarkMode ? Colors.lightBlue : Colors.blue[800], // Set the color of the checkbox when selected
                        checkColor: Colors.white, // Set the color of the check mark inside the checkbox
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 25.0),
                    child: Text(
                      // Doesnt do anything 
                      'Forgot Password?',
                      style: TextStyle(color: isDarkMode ? Colors.lightBlue : Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Pass signUserIn method to SignInButton
              SignInButton(
                onTap: () => signUserIn(context),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Create a new user 
                  Text(
                    "Haven't got an account? ",
                    style: TextStyle(color: isDarkMode ? Color(0xFFB1B6BB) : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Register Now',
                    style: TextStyle(color: isDarkMode ? Colors.lightBlue : Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}