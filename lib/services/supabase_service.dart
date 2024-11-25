import 'package:flutter/foundation.dart' show debugPrint;
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

  static bool isValidName(String name) {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(name);
  }

  static String formatName(String name) {
    return name;  // Preserve the original case and format
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      debugPrint('Checking if user exists: $email');
      
      // Validate name format
      if (!isValidName(name)) {
        throw const AuthException(
          'Invalid username format. Username must contain only letters and numbers (no spaces or special characters).',
        );
      }

      final formattedName = formatName(name);
      
      // Try to sign in first to check if user exists
      try {
        await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        // If we get here, user exists and password is correct
        throw const AuthException(
          'User already exists',
        );
      } catch (e) {
        if (e is AuthException && e.message == 'User already exists') {
          rethrow;
        }
        // If we get here, user doesn't exist, continue with sign up
      }

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': formattedName},
      );

      return response;
    } catch (e) {
      debugPrint('Error in signUp: $e');
      rethrow;
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

  static String? getUserName() {
    final user = currentUser;
    if (user == null) return null;
    return user.userMetadata?['display_name'] as String?;
  }

  static Future<void> updateUserName(String name) async {
    try {
      // Validate name format
      if (!isValidName(name)) {
        throw const AuthException(
          'Invalid username format. Username must contain only letters and numbers (no spaces or special characters).',
        );
      }

      final formattedName = formatName(name);
      
      await client.auth.updateUser(
        UserAttributes(
          data: {'display_name': formattedName},
        ),
      );
    } catch (e) {
      debugPrint('Error updating user name: $e');
      rethrow;
    }
  }

  // Phone Authentication Methods
  static Future<bool> isPhoneRegistered(String phone) async {
    try {
      // Try to get user by phone number
      final response = await client.rpc(
        'get_user_by_phone',
        params: {'phone_number': phone},
      );
      
      // If we get a response, the phone is registered
      return response != null && response.toString().isNotEmpty;
    } catch (e) {
      debugPrint('Error checking phone registration: $e');
      return false;
    }
  }

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
