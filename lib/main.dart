import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/email_confirmation_screen.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'widgets/custom_snackbar.dart';

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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Auth Demo',
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
                  debugPrint('Has data: ${snapshot.hasData}');
                  debugPrint('Connection state: ${snapshot.connectionState}');
                  if (snapshot.hasData) {
                    debugPrint('Session: ${snapshot.data?.session?.user.id}');
                    debugPrint('Event type: ${snapshot.data?.event}');
                    debugPrint('Current user: ${SupabaseService.currentUser?.id}');
                  }

                  if (snapshot.hasError) {
                    debugPrint('Auth state error: ${snapshot.error}');
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  // Check if we're still waiting for the initial connection
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    debugPrint('Waiting for auth state connection...');
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final session = snapshot.data?.session;
                  final event = snapshot.data?.event;
                  
                  debugPrint('Session state: ${session != null ? "Active" : "Null"}');
                  debugPrint('Auth event: $event');
                  
                  // Force a rebuild when auth state changes
                  if (event == AuthChangeEvent.signedIn || 
                      event == AuthChangeEvent.signedOut ||
                      event == AuthChangeEvent.tokenRefreshed) {
                    debugPrint('Significant auth event detected: $event');
                  }

                  return session == null ? const LoginScreen() : const HomeScreen();
                },
              ),
            ),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/email-confirmation': (context) => const EmailConfirmationScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
  }

  Future<void> _initializeDeepLinks() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Initialize deep linking
      final appLinks = AppLinks();
      
      // Listen to incoming links
      appLinks.allUriLinkStream.listen(
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
      final initialUri = await appLinks.getInitialAppLink();
      if (initialUri != null && mounted) {
        debugPrint('Got initial deep link: $initialUri');
        handleDeepLink(initialUri);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing deep links: $e');
      if (mounted) {
        setState(() {
          _error = 'Error initializing deep links: $e';
          _isLoading = false;
        });
      }
    }
  }

  void handleDeepLink(Uri uri) async {
    if (!mounted) return;
    
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _initializeDeepLinks,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
