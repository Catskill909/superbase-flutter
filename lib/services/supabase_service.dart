import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://sfzfcofsudrirhjbokqs.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmemZjb2ZzdWRyaXJoamJva3FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzIxNTk4MzQsImV4cCI6MjA0NzczNTgzNH0.MCBkLrGg1LchNwd6qQkrAF0BPu2krWiZTy9WmNZk4jo';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
      debug: true,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting to sign up user: $email');
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      debugPrint('Sign up response received:');
      debugPrint('User: ${response.user?.toJson()}');
      debugPrint('Session: ${response.session?.toJson()}');
      debugPrint('Raw response: $response');

      if (response.user == null) {
        throw const AuthException('Failed to create user account');
      }

      return response;
    } catch (e, stackTrace) {
      debugPrint('Error during sign up: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting to sign in user: $email');
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('Sign in response received:');
      debugPrint('User: ${response.user?.toJson()}');
      debugPrint('Session: ${response.session?.toJson()}');
      return response;
    } catch (e) {
      debugPrint('Error during sign in: $e');
      rethrow;
    }
  }

  static Future<bool> isUserConfirmed(String email) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: 'dummy-password', // This will fail, but we'll check the error
      );
      return response.user != null;
    } catch (e) {
      if (e is AuthException) {
        // If the error is about wrong password, the email is confirmed
        return e.message.contains('Invalid login credentials');
      }
      return false;
    }
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  static Future<UserResponse> updatePassword(String newPassword) async {
    return await client.auth.updateUser(
      UserAttributes(
        password: newPassword,
      ),
    );
  }

  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  static User? get currentUser => client.auth.currentUser;
}
