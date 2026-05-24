import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/ui/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Note: This will fail until google-services.json is added
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const RunnerRushApp());
}

class RunnerRushApp extends StatelessWidget {
  const RunnerRushApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runner Rush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B4F8A)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
