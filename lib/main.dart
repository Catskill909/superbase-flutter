import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

// Screen imports
import 'package:supabase_auth_app/screens/home_screen.dart';
import 'package:supabase_auth_app/screens/login_screen.dart';
import 'package:supabase_auth_app/screens/register_screen.dart';
import 'package:supabase_auth_app/screens/forgot_password_screen.dart';
import 'package:supabase_auth_app/screens/email_confirmation_screen.dart';
import 'package:supabase_auth_app/screens/phone_login_screen.dart';
import 'package:supabase_auth_app/screens/reset_password_screen.dart';
import 'package:supabase_auth_app/screens/verify_otp_screen.dart';

// Service imports
import 'package:supabase_auth_app/services/supabase_service.dart';

// Theme import
import 'package:supabase_auth_app/theme/app_theme.dart';

// Widget imports
import 'package:supabase_auth_app/widgets/custom_snackbar.dart';

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    debugPrint('Initializing Supabase...');
    await SupabaseService.initialize();
    debugPrint('Supabase initialization complete');
  } catch (e, stackTrace) {
    debugPrint('Error initializing Supabase: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

void main() {
  runZonedGuarded(() async {
    await initializeApp();
    runApp(const MyApp());
  }, (error, stackTrace) {
    debugPrint('Error in main: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks appLinks;

  @override
  void initState() {
    super.initState();
    appLinks = AppLinks();

    // Listen for deep links
    appLinks.uriLinkStream.listen((uri) {
      debugPrint('Deep link received: $uri');
      handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Error handling deep link: $err');
      if (mounted) {
        showCustomSnackbar(
          context: context, 
          message: 'Error handling deep link: $err',
          isSuccess: false,
          actionLabel: 'Retry',
          onActionPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          },
        );
      }
    });

    // Check for initial app link
    _checkInitialAppLink();
  }

  Future<void> _checkInitialAppLink() async {
    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('Initial deep link: $initialUri');
        handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error checking initial app link: $e');
      if (mounted) {
        showCustomSnackbar(
          context: context, 
          message: 'Error checking initial app link: $e',
          isSuccess: false,
          actionLabel: 'Retry',
          onActionPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          },
        );
      }
    }
  }

  void handleDeepLink(Uri uri) {
    if (uri.scheme == 'io.supabase.flutterquickstart') {
      if (uri.host == 'login-callback') {
        debugPrint('Login callback received');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      } else if (uri.host == 'reset-callback') {
        final token = uri.queryParameters['token'];
        debugPrint('Reset callback received with token: $token');
        Navigator.pushNamed(
          context,
          '/reset-password',
          arguments: token,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Auth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: StreamBuilder<AuthState>(
        stream: SupabaseService.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          debugPrint('Auth state changed:');
          debugPrint('- Has data: ${snapshot.hasData}');
          debugPrint('- Event: ${snapshot.data?.event}');
          debugPrint('- Session: ${snapshot.data?.session != null}');
          
          if (snapshot.connectionState == ConnectionState.active) {
            final session = snapshot.data?.session;
            final user = session?.user;
            
            if (user == null) {
              return const LoginScreen();
            }
            
            // Check authentication method
            final authMethod = user.phone != null ? 'phone' : 'email';
            debugPrint('Auth method: $authMethod');
            
            if (authMethod == 'email' && user.emailConfirmedAt == null) {
              return const EmailConfirmationScreen();
            }
            
            return const HomeScreen();
          }
          
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/email-confirmation': (context) => const EmailConfirmationScreen(),
        '/phone-login': (context) => const PhoneLoginScreen(),
        '/verify-otp': (context) => VerifyOTPScreen(
          email: ModalRoute.of(context)?.settings.arguments as String,
        ),
        '/home': (context) => const HomeScreen(),
        '/reset-password': (context) => ResetPasswordScreen(
          token: ModalRoute.of(context)?.settings.arguments as String?,
        ),
      },
    );
  }
}
