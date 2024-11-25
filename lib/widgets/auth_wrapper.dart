import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../services/supabase_service.dart';
import '../widgets/custom_snackbar.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Stream<AuthState> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = SupabaseService.client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        debugPrint('Auth state changed:');
        debugPrint('- Has data: ${snapshot.hasData}');
        debugPrint('- Event: ${snapshot.data?.event}');
        debugPrint('- Session: ${snapshot.data?.session != null}');

        final session = snapshot.data?.session;
        
        if (session != null) {
          final user = session.user;
          if (user.emailConfirmedAt != null) {
            return const HomeScreen();
          } else {
            // Show a message about email verification
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showCustomSnackbar(
                context: context,
                message: 'Please verify your email to continue.',
                isSuccess: false,
                duration: const Duration(seconds: 5),
              );
            });
            return const LoginScreen();
          }
        }
        
        return const LoginScreen();
      },
    );
  }
}
