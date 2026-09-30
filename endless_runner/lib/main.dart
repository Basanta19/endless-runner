import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/ui/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
