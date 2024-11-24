import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
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
      debugPrint('Checking if user exists: $email');
      
      // Try to sign in first to check if user exists
      try {
        await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        // If we get here, user exists and password is correct
        throw const AuthException(
          'This email is already registered. Please sign in instead.',
        );
      } on AuthException catch (e) {
        // If error is "Invalid login credentials", user doesn't exist
        // If error is "Email not confirmed", user exists but needs verification
        if (e.message.contains('Email not confirmed')) {
          throw const AuthException(
            'This email is already registered but not verified. Please check your email for the verification link.',
          );
        } else if (!e.message.contains('Invalid login credentials')) {
          // Some other auth error occurred
          rethrow;
        }
        // If we get here, user doesn't exist, proceed with signup
      }
      
      debugPrint('Attempting to sign up new user: $email');
      
      final response = await client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: kIsWeb 
            ? null 
            : 'com.starkey.supabase://auth-callback/',
        data: {
          'email_confirm': true,
        },
      );

      debugPrint('Sign up response received: ${response.user?.id}');
      
      // Check if email confirmation was sent
      if (response.user != null && response.session == null) {
        debugPrint('Email confirmation required. Confirmation email should be sent.');
      } else {
        debugPrint('Unexpected response state. Session: ${response.session != null}, User: ${response.user != null}');
      }
      
      return response;
    } on AuthException catch (e) {
      debugPrint('Auth Exception during sign up: ${e.message}');
      if (e.message.toLowerCase().contains('rate limit')) {
        throw const AuthException(
          'Too many signup attempts. Please wait a few minutes before trying again.',
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
      debugPrint('Signing out user...');
      await client.auth.signOut(
        scope: SignOutScope.global,
      );
      debugPrint('Sign out successful');
    } catch (e) {
      debugPrint('Error during sign out: $e');
      rethrow;
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(
        email,
      );
    } catch (e) {
      debugPrint('Error during password reset: $e');
      rethrow;
    }
  }

  static Future<void> verifyOTPAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      // First verify the OTP
      await client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );

      // Then update the password
      await client.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
    } catch (e) {
      debugPrint('Error during OTP verification and password reset: $e');
      rethrow;
    }
  }

  static Future<void> updatePassword(String newPassword, [String? token]) async {
    try {
      if (token != null) {
        // This is a password recovery flow
        await client.auth.verifyOTP(
          token: token,
          type: OtpType.recovery,
        );
      }
      
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

  // Phone Authentication Methods
  static Future<AuthResponse> signInWithPhone({
    required String phone,
  }) async {
    try {
      debugPrint('=================== PHONE SIGN IN START ===================');
      debugPrint('Attempting to sign in with phone: $phone');
      
      // First request the OTP
      await client.auth.signInWithOtp(
        phone: phone,
      );

      // Return a placeholder AuthResponse since OTP was sent successfully
      return AuthResponse(
        session: null,
        user: null,
      );
    } catch (e) {
      debugPrint('=================== PHONE SIGN IN ERROR ===================');
      debugPrint('Error during phone sign in: $e');
      rethrow;
    }
  }

  static Future<AuthResponse> verifyPhoneOTP({
    required String phone,
    required String token,
  }) async {
    try {
      debugPrint('=================== VERIFY OTP START ===================');
      debugPrint('Attempting to verify OTP for phone: $phone');
      
      final response = await client.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: token,
      );

      debugPrint('=================== VERIFY OTP RESPONSE ===================');
      debugPrint('User: ${response.user?.id}');
      debugPrint('Session: ${response.session?.user.id}');
      
      // Ensure we have a valid session
      if (response.session == null) {
        throw const AuthException('Failed to create session after phone verification');
      }
      
      // The session is already set by verifyOTP, no need to set it manually
      debugPrint('Session established successfully');
      
      return response;
    } catch (e) {
      debugPrint('=================== VERIFY OTP ERROR ===================');
      debugPrint('Error during OTP verification: $e');
      rethrow;
    }
  }
}
