import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_auth_app/services/supabase_service.dart';

void main() {
  group('SupabaseService Tests', () {
    setUpAll(() async {
      // Initialize Supabase with test configuration
      await Supabase.initialize(
        url: 'https://test-project.supabase.co', 
        anonKey: 'fake-anon-key',
      );
    });

    test('SupabaseService initialization', () async {
      await expectLater(
        SupabaseService.initialize(),
        completes,
      );
    });

    test('Current user is initially null', () {
      expect(SupabaseService.currentUser, isNull);
    });

    test('Sign up method works correctly', () async {
      const testEmail = 'test@example.com';
      const testPassword = 'StrongPassword123!';

      try {
        final response = await SupabaseService.signUp(
          email: testEmail,
          password: testPassword,
        );

        expect(response.user, isNotNull);
        expect(response.user?.email, equals(testEmail));
      } catch (e) {
        fail('Sign up failed: $e');
      }
    });

    tearDownAll(() async {
      // Clean up Supabase initialization
      await Supabase.instance.dispose();
    });
  });
}
