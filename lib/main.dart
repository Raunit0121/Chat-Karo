import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'constants.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/user_list_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/call_history_screen.dart';
import 'screens/reaction_demo_screen.dart';
import 'screens/reaction_test_screen.dart';
import 'screens/simple_reaction_test.dart';
import 'screens/debug_reaction_test.dart';
import 'services/call_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final CallManager _callManager = CallManager();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Initialize call manager after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _navigatorKey.currentContext;
      if (context != null) {
        _callManager.initialize(context);
      }
    });
  }

  @override
  void dispose() {
    _callManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatKaro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/users': (context) => UserListScreen(),
        '/chat': (context) => const ChatScreen(),
        '/calls': (context) => const CallHistoryScreen(),
        '/reaction-demo': (context) => const ReactionDemoScreen(),
        '/reaction-test': (context) => const ReactionTestScreen(),
        '/simple-reaction-test': (context) => const SimpleReactionTest(),
        '/debug-reaction-test': (context) => const DebugReactionTest(),
      },
      navigatorKey: _navigatorKey,
      builder: (context, child) {
        // Update call manager context when navigating
        _callManager.updateContext(context);
        return child!;
      },
    );
  }
}
