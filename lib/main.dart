import 'package:flutter/material.dart';
import 'package:production/Screens/splash/splashscreen.dart';
import 'package:production/Screens/Attendance/dailogei.dart';
import 'package:provider/provider.dart';

void main() {
  IntimeSyncService().startSync(); // Start background FIFO sync at app startup
  runApp(
    MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
