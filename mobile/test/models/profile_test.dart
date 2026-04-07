import 'package:flutter_test/flutter_test.dart';
import 'package:friendly/models/profile.dart';

void main() {
  group('Profile', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'user-123',
        'display_name': 'Alice',
        'email': 'alice@example.com',
        'phone_number': '+1234567890',
        'metadata': {'onboarding_complete': true, 'friend_language': 'gifts'},
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-06-01T00:00:00.000Z',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'user-123');
      expect(profile.displayName, 'Alice');
      expect(profile.email, 'alice@example.com');
      expect(profile.phoneNumber, '+1234567890');
      expect(profile.metadata?['onboarding_complete'], true);
      expect(profile.metadata?['friend_language'], 'gifts');
      expect(profile.createdAt, isA<DateTime>());
      expect(profile.updatedAt, isA<DateTime>());
    });

    test('fromJson handles null optional fields', () {
      final json = {'id': 'user-456'};

      final profile = Profile.fromJson(json);

      expect(profile.id, 'user-456');
      expect(profile.displayName, isNull);
      expect(profile.email, isNull);
      expect(profile.phoneNumber, isNull);
      expect(profile.metadata, isNull);
      expect(profile.createdAt, isNull);
      expect(profile.updatedAt, isNull);
    });

    test('toJson serialises back correctly', () {
      final profile = Profile(
        id: 'user-789',
        displayName: 'Bob',
        email: 'bob@example.com',
      );

      final json = profile.toJson();

      expect(json['id'], 'user-789');
      expect(json['display_name'], 'Bob');
      expect(json['email'], 'bob@example.com');
    });

    test('fromJson handles new user with empty metadata', () {
      final json = {
        'id': 'new-user',
        'display_name': 'NewUser',
        'metadata': <String, dynamic>{},
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'new-user');
      expect(profile.metadata, isNotNull);
      expect(profile.metadata, isEmpty);
    });
  });
}
