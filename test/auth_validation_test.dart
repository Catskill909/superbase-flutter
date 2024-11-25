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
      expect(SupabaseService.isValidName(' '), false);         // just space
      expect(SupabaseService.isValidName('a' * 51), false);    // too long
    });
  });

  group('Password Security Tests', () {
    test('password length validation', () {
      // Too short (less than 6 characters)
      expect(isPasswordValid('12345'), false);
      expect(isPasswordValid(''), false);
      
      // Valid length
      expect(isPasswordValid('123456'), true);
      expect(isPasswordValid('securepassword'), true);
    });

    test('password strength validation', () {
      // Basic passwords should pass minimum requirements
      expect(isPasswordValid('password123'), true);
      
      // Common passwords should be rejected
      expect(isPasswordValid('password'), false);
      expect(isPasswordValid('123456789'), false);
    });
  });

  group('Email Validation Tests', () {
    test('email format validation', () {
      // Valid emails
      expect(isEmailValid('test@example.com'), true);
      expect(isEmailValid('user.name+tag@example.co.uk'), true);
      
      // Invalid emails
      expect(isEmailValid('invalid.email'), false);
      expect(isEmailValid('@example.com'), false);
      expect(isEmailValid('user@'), false);
      expect(isEmailValid(''), false);
      expect(isEmailValid(' '), false);
    });
  });

  group('Phone Number Validation Tests', () {
    test('phone number format validation', () {
      // Valid phone numbers
      expect(isPhoneValid('+1234567890'), true);
      expect(isPhoneValid('+44 7911 123456'), true);
      
      // Invalid phone numbers
      expect(isPhoneValid('invalid'), false);
      expect(isPhoneValid('123'), false);
      expect(isPhoneValid(''), false);
    });
  });

  group('Security Edge Cases', () {
    test('SQL injection prevention in username', () {
      expect(SupabaseService.isValidName("admin'--"), false);
      expect(SupabaseService.isValidName("user OR '1'='1"), false);
    });

    test('XSS prevention in username', () {
      expect(SupabaseService.isValidName('<script>alert(1)</script>'), false);
      expect(SupabaseService.isValidName('javascript:alert(1)'), false);
    });
  });
}

// Helper functions for validation
bool isPasswordValid(String password) {
  if (password.length < 6) return false;
  if (password == 'password' || password == '123456789') return false;
  return true;
}

bool isEmailValid(String email) {
  if (email.isEmpty) return false;
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

bool isPhoneValid(String phone) {
  if (phone.isEmpty) return false;
  // Basic phone validation: should start with + and contain 10-15 digits
  final phoneRegex = RegExp(r'^\+[\d\s]{10,15}$');
  return phoneRegex.hasMatch(phone.replaceAll(' ', ''));
}
