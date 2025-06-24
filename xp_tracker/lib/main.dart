import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'pages/login_page.dart';
import 'pages/home.dart';
import 'theme/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // check if logged in 
  Future<int?> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(448, 997), // Pixel 8 Pro logical size because was built on that
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: themeProvider.isDarkMode
                  ? ThemeMode.dark
                  : ThemeMode.light,
              home: FutureBuilder<int?>(
                future: _checkLoginStatus(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // If user previously logged in navigate home
                  if (snapshot.hasData && snapshot.data != null) {
                    return HomePage(); 
                  } else {
                    return const LoginPage();
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

