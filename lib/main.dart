import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Core
import 'core/theme/app_theme.dart';

// Services
import 'data/services/local_storage_service.dart';

// ViewModels
import 'presentation/viewmodels/home_viewmodel.dart';
import 'presentation/viewmodels/habit_viewmodel.dart';
import 'presentation/viewmodels/mood_viewmodel.dart';
import 'presentation/viewmodels/chat_viewmodel.dart';
import 'presentation/viewmodels/suggestion_viewmodel.dart';

// Auth Screens
import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/screens/auth/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/signup_screen.dart';

// Main Screens
import 'presentation/screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Local Storage
  await LocalStorageService().init();

  // Set system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => HabitViewModel()),
        ChangeNotifierProvider(create: (_) => MoodViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => SuggestionViewModel()),
      ],
      child: MaterialApp(
        title: 'AI Life Coach',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        
        // Start from Splash
        initialRoute: '/',
        
        // Routes
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/main': (context) => const MainNavigation(),
        },
      ),
    );
  }
}

