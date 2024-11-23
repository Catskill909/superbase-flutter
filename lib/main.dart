import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

// Screen imports
import 'package:supabase_auth_app/screens/home_screen.dart';
import 'package:supabase_auth_app/screens/login_screen.dart';
import 'package:supabase_auth_app/screens/register_screen.dart';
import 'package:supabase_auth_app/screens/forgot_password_screen.dart';
import 'package:supabase_auth_app/screens/email_confirmation_screen.dart';
import 'package:supabase_auth_app/screens/phone_login_screen.dart';

// Service imports
import 'package:supabase_auth_app/services/supabase_service.dart';

// Theme import
import 'package:supabase_auth_app/theme/app_theme.dart';

// Widget imports
import 'package:supabase_auth_app/widgets/custom_snackbar.dart';

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
    // We'll handle the error in the UI
  }
}

void main() async {
  await initializeApp();
  runApp(const MyApp());
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
      // Handle deep links here
      // Example: navigate to specific screen based on the URI
      if (uri.path.contains('/login')) {
        // Navigate to login screen
      } else if (uri.path.contains('/register')) {
        // Navigate to register screen
      }
    }, onError: (err) {
      // Handle errors
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
        // Handle the initial app link
        // Similar logic to the stream listener
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Auth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(
              child: StreamBuilder<AuthState>(
                stream: SupabaseService.client.auth.onAuthStateChange,
                builder: (context, snapshot) {
                  debugPrint('=================== AUTH STATE CHANGE ===================');
                  debugPrint('Has error: ${snapshot.hasError}');
                  
                  // Determine initial route based on authentication state
                  if (snapshot.hasError) {
                    return const LoginScreen();
                  }
                  
                  final session = snapshot.data?.session;
                  if (session != null) {
                    return const HomeScreen();
                  } else {
                    return const LoginScreen();
                  }
                },
              ),
            ),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/email-confirmation': (context) => const EmailConfirmationScreen(),
        '/phone-login': (context) => const PhoneLoginScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
  }

  Future<void> _initializeDeepLinks() async {
    if (!mounted) return;

    setState(() {
      // _isLoading = true; // Commented out since _isLoading is final
      _error = null;
    });

    try {
      // Initialize deep linking
      final appLinks = AppLinks();
      
      // Listen to incoming links
      appLinks.uriLinkStream.listen(
        (uri) {
          debugPrint('Received deep link: $uri');
          handleDeepLink(uri);
        },
        onError: (err) {
          debugPrint('Error handling deep link: $err');
          if (mounted) {
            setState(() {
              _error = 'Error handling deep link: $err';
            });
          }
        },
      );
      
      // Check for initial link
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null && mounted) {
        debugPrint('Got initial deep link: $initialUri');
        handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error initializing deep links: $e');
      if (mounted) {
        setState(() {
          _error = 'Error initializing deep links: $e';
        });
      }
    }
  }

  void handleDeepLink(Uri? uri) async {
    if (!mounted) return;
    
    if (uri == null) return;
    
    debugPrint('Received deep link: $uri');
    
    if (uri.scheme == 'com.starkey.supabase') {
      if (uri.host == 'auth-callback') {
        final token = uri.queryParameters['token'];
        final type = uri.queryParameters['type'];
        
        debugPrint('Auth callback received - Token: $token, Type: $type');
        
        try {
          // Refresh the session to get the latest email verification status
          await SupabaseService.client.auth.refreshSession();
          
          if (mounted) {
            showCustomSnackbar(
              context: context,
              message: 'Email verified successfully!',
              isSuccess: true,
              actionLabel: 'Continue',
              onActionPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            );
          }
        } catch (e) {
          debugPrint('Error refreshing session: $e');
          if (mounted) {
            showCustomSnackbar(
              context: context,
              message: 'Please try logging in to continue.',
              isSuccess: false,
              actionLabel: 'Login',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.white,
            size: 50,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text('Error: $_error'),
        ),
      );
    }

    return widget.child;
  }
}
