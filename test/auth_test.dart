import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_auth_app/services/supabase_service.dart';

@GenerateMocks([GoTrueClient])
import 'auth_test.mocks.dart';

void main() {
  late MockGoTrueClient mockAuthClient;

  setUp(() {
    mockAuthClient = MockGoTrueClient();
  });

  group('Authentication Tests', () {
    test('successful login should return user session', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      final mockUser = User(
        id: '123',
        appMetadata: const {},
        userMetadata: const {},
        aud: '',
        email: email,
        createdAt: DateTime.now().toString(),
      );
      final mockSession = Session(
        accessToken: 'mock_token',
        tokenType: '',
        user: mockUser,
      );
      final mockAuthResponse = AuthResponse(
        session: mockSession,
        user: mockUser,
      );

      when(mockAuthClient.signInWithPassword(
        email: email,
        password: password,
      )).thenAnswer((_) async => mockAuthResponse);

      // Act & Assert
      expect(
        SupabaseService.signIn(
          email: email,
          password: password,
        ),
        completion(equals(mockAuthResponse)),
      );
    });

    test('invalid credentials should throw AuthException', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'wrongpassword';

      when(mockAuthClient.signInWithPassword(
        email: email,
        password: password,
      )).thenThrow(const AuthException('Invalid credentials'));

      // Act & Assert
      expect(
        () => SupabaseService.signIn(
          email: email,
          password: password,
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('network error should throw appropriate exception', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';

      when(mockAuthClient.signInWithPassword(
        email: email,
        password: password,
      )).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => SupabaseService.signIn(
          email: email,
          password: password,
        ),
        throwsException,
      );
    });
  });
}
