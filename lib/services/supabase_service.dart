import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://sfzfcofsudrirhjbokqs.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmemZjb2ZzdWRyaXJoamJva3FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzIxNTk4MzQsImV4cCI6MjA0NzczNTgzNH0.MCBkLrGg1LchNwd6qQkrAF0BPu2krWiZTy9WmNZk4jo';

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('SupabaseService already initialized');
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: anonKey,
      );
      _isInitialized = true;
      debugPrint('SupabaseService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing SupabaseService: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  static User? get currentUser => client.auth.currentUser;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting to sign up user: $email');
      
      final response = await client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'com.starkey.supabase://auth-callback/signup-confirmed',
      );

      debugPrint('Sign up response received: ${response.user?.id}');
      return response;
    } on AuthException catch (e) {
      debugPrint('Auth Exception during sign up: ${e.message}');
      if (e.message.toLowerCase().contains('rate limit')) {
        throw const AuthException(
          'Please wait a few minutes before trying to sign up again.',
        );
      }
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error during sign up: $e');
      debugPrint('Stack trace: $stackTrace');
      throw const AuthException(
        'An unexpected error occurred. Please try again later.',
      );
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('=================== LOGIN START ===================');
      debugPrint('Attempting to sign in user: $email');
      
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint('=================== LOGIN RESPONSE ===================');
      debugPrint('User: ${response.user?.id}');
      debugPrint('Session: ${response.session?.user.id}');
      debugPrint('Email verified: ${response.user?.emailConfirmedAt != null}');
      
      return response;
    } catch (e) {
      debugPrint('=================== LOGIN ERROR ===================');
      debugPrint('Error during sign in: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Error during sign out: $e');
      rethrow;
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.starkey.supabase://auth-callback',
      );
    } catch (e) {
      debugPrint('Error during password reset: $e');
      rethrow;
    }
  }

  static Future<void> updatePassword(String newPassword) async {
    try {
      await client.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
    } catch (e) {
      debugPrint('Error updating password: $e');
      rethrow;
    }
  }
}
