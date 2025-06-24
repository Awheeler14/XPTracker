import 'package:flutter/material.dart';

// Button at bottom of login page, logs user in when pressed 
class SignInButton extends StatelessWidget{

  final Function()? onTap;

  const SignInButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 40),
      // Using inkwell to help show button is being pressed
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.green.withValues(alpha: 0.3),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Color(0xFF2A7F41),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.2), 
              spreadRadius: 5,
              blurRadius: 10,
              offset: Offset(0, 3), 
            ),
          ],
            ),
          child: Center(
            child: Text(
              'Sign In',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            )
          )
        ),
      ),
    );
  }
}