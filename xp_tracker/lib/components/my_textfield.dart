import 'package:flutter/material.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';

// Used to take in username and password when loggging on 
// Can pass in the controller, hint text and the option to obscure text (for password)
class MyTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const MyTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(
          color: isDarkMode ? Color(0xFFB1B6BB) : Colors.black,
        ),
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color:isDarkMode ? Color(0xFF363233) : Colors.grey[300]!,),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black ),
          ),
          fillColor: isDarkMode ? Color(0xFF363233) : Colors.grey[300],
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }
}
