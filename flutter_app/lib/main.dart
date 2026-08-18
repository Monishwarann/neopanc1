import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/central_providers.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_wrapper.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sensor_screen.dart';
import 'screens/prediction_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/about_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserStateProvider()),
        ChangeNotifierProvider(create: (_) => DateTimeStateProvider()),
        ChangeNotifierProxyProvider<UserStateProvider, ESP32StateProvider>(
          create: (_) => ESP32StateProvider(),
          update: (_, user, esp32) => esp32!..updateDependencies(user.userId, user.baseUrl),
        ),
        ChangeNotifierProxyProvider<UserStateProvider, AIStateProvider>(
          create: (_) => AIStateProvider(),
          update: (_, user, ai) => ai!..updateDependencies(user.userId, user.baseUrl),
        ),
      ],
      child: const NeoPancApp(),
    ),
  );
}

class NeoPancApp extends StatelessWidget {
  const NeoPancApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeoPanc',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Defaulting to premium dark mode as requested, but supports both
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const MainWrapper(),
        '/sensors': (context) => const SensorScreen(),
        '/prediction': (context) => const PredictionScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}

// User state manager
class UserStateProvider with ChangeNotifier {
  String? _userId;
  String? _username;
  String? _email;
  
  // Real-time Centralized Profile Data
  Map<String, dynamic>? _profileData;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  
  // Flask Endpoint Host Configurations
  String _baseUrl = "https://ash-backend-7ys6.onrender.com"; 

  String? get userId => _userId;
  String? get username => _username;
  String? get email => _email;
  String get baseUrl => _baseUrl;
  Map<String, dynamic>? get profileData => _profileData;

  void setUser(String id, String name, String mail) {
    _userId = id;
    _username = name;
    _email = mail;
    
    // Start listening to Firestore real-time updates for the centralized profile
    _profileSub?.cancel();
    _profileSub = FirebaseService().streamUserProfile(id).listen((snapshot) {
      if (snapshot.exists) {
        _profileData = snapshot.data();
      } else {
        // Automatically initialize default profile if missing in Firestore
        _profileData = {
          'username': name,
          'email': mail,
          'phone': '',
          'age': 0,
          'gender': '',
          'bloodGroup': '',
          'height': 0.0,
          'weight': 0.0,
          'bmi': 0.0,
          'address': '',
          'profileImageUrl': '',
        };
        FirebaseService().updateUserProfile(id, _profileData!);
      }
      notifyListeners();
    }, onError: (error) {
      print("Error streaming user profile: $error");
      // Use locally initialized fallback profile if database read fails or requires index
      _profileData = {
        'username': name,
        'email': mail,
        'phone': '',
        'age': 0,
        'gender': '',
        'bloodGroup': '',
        'height': 0.0,
        'weight': 0.0,
        'bmi': 0.0,
        'address': '',
        'profileImageUrl': '',
      };
      notifyListeners();
    });
    
    notifyListeners();
  }

  void setBaseUrl(String url) {
    _baseUrl = url;
    notifyListeners();
  }

  void clearUser() {
    _userId = null;
    _username = null;
    _email = null;
    _profileData = null;
    _profileSub?.cancel();
    _profileSub = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }
}
