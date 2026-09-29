import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'master_layout.dart';
import 'models/user_model.dart';
import 'onboarding_screen.dart';
import 'screens/apotek/apoteker_home_screen.dart';
import 'screens/dokter/dokter_home_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inisialisasi Firebase Mobile
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 Firebase GIAT initialized successfully (giat-3ac67)');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization notice: $e');
  }

  // Inisialisasi Local Storage
  await StorageService().init();

  // Cek apakah ada sesi login tersimpan
  final String? token = await StorageService().getToken();
  UserModel? savedUser = await StorageService().getUser();

  // Validasi sesi ke backend via /me jika token ada
  if (token != null && token.isNotEmpty) {
    try {
      final user = await AuthService().getCurrentUser();
      if (user != null) {
        savedUser = user;
      }
    } catch (_) {}
  }

  runApp(GiatApp(initialUser: savedUser));
}

class GiatApp extends StatelessWidget {
  final UserModel? initialUser;

  const GiatApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    Widget initialScreen = const OnboardingScreen();

    // Auto-login jika sesi tersimpan masih valid
    if (initialUser != null) {
      final role = initialUser!.role.toLowerCase();
      if (role == 'dokter') {
        initialScreen = DokterHomeScreen(doctorName: initialUser!.nama);
      } else if (role == 'apotek' || role == 'apoteker') {
        initialScreen = ApotekerHomeScreen(apotekerName: initialUser!.nama);
      } else {
        initialScreen = MasterLayout(userName: initialUser!.nama);
      }
    }

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
      home: initialScreen,
    );
  }
}
