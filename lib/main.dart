import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const GiatApp());
}

class GiatApp extends StatelessWidget {
  const GiatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GIAT - Ginjal Sehat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF065A37),
          primary: const Color(0xFF065A37),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}
