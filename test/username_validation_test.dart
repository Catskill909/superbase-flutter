import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_auth_app/services/supabase_service.dart';

void main() {
  group('Username Validation Tests', () {
    test('valid usernames should pass validation', () {
      expect(SupabaseService.isValidName('john123'), true);
      expect(SupabaseService.isValidName('ADMIN2024'), true);
      expect(SupabaseService.isValidName('TechUser'), true);
    });

    test('invalid usernames should fail validation', () {
      expect(SupabaseService.isValidName('john smith'), false); // has space
      expect(SupabaseService.isValidName('john@123'), false);  // has special char
      expect(SupabaseService.isValidName(''), false);          // empty
    });
  });
}
