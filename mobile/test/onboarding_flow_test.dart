import 'package:flutter_test/flutter_test.dart';
import 'package:friendly/constants/friend_language.dart';
import 'package:friendly/components/avatar/avatar_types.dart';
import 'package:friendly/models/profile.dart';

void main() {
  group('Onboarding flow — data layer', () {
    group('Avatar step', () {
      test('new user starts with default AvatarConfig', () {
        // A brand new profile has no metadata
        final profile = Profile(id: 'new-user', metadata: null);
        final config = AvatarConfig.fromMetadata(profile.metadata);

        expect(config.style, 'circle');
        expect(config.hasCustomConfig, false);
      });

      test('avatar metadata can be merged into empty profile metadata', () {
        const config = AvatarConfig(style: 'default', eyes: 'wink');
        final profile = Profile(id: 'new-user', metadata: null);

        final merged = <String, dynamic>{
          ...?profile.metadata,
          ...config.toMetadata(),
        };

        expect(merged['avatar_style'], 'default');
        expect(merged['avatar_eyes'], 'wink');
        expect(merged.containsKey('avatar_skinColor'), true);
      });

      test('avatar metadata can be merged into existing profile metadata', () {
        const config = AvatarConfig(style: 'circle', mouth: 'tongue');
        final profile = Profile(
          id: 'existing-user',
          metadata: {'some_pref': 'value'},
        );

        final merged = <String, dynamic>{
          ...?profile.metadata,
          ...config.toMetadata(),
        };

        expect(merged['some_pref'], 'value');
        expect(merged['avatar_style'], 'circle');
        expect(merged['avatar_mouth'], 'tongue');
      });
    });

    group('Contact step', () {
      test('email and phone can be provided for profile update', () {
        const email = 'test@example.com';
        const phone = '+1234567890';

        final body = {'email': email.trim(), 'phone_number': phone.trim()};

        expect(body['email'], 'test@example.com');
        expect(body['phone_number'], '+1234567890');
      });

      test('whitespace is trimmed from contact info', () {
        const email = '  test@example.com  ';
        const phone = '  +1234567890  ';

        final body = {'email': email.trim(), 'phone_number': phone.trim()};

        expect(body['email'], 'test@example.com');
        expect(body['phone_number'], '+1234567890');
      });
    });

    group('Quiz step', () {
      test('quizQuestions has 5 questions', () {
        expect(quizQuestions.length, 5);
      });

      test('each question has 5 options covering all languages', () {
        for (final q in quizQuestions) {
          expect(q.options.length, 5);
          final langs = q.options.map((o) => o.language).toSet();
          expect(langs, containsAll(FriendLanguage.values));
        }
      });

      test('tallyQuizResults picks most common answer', () {
        final answers = [
          FriendLanguage.gifts,
          FriendLanguage.gifts,
          FriendLanguage.gifts,
          FriendLanguage.time,
          FriendLanguage.words,
        ];

        expect(tallyQuizResults(answers), FriendLanguage.gifts);
      });

      test('tallyQuizResults breaks ties by enum order', () {
        // words < acts in enum declaration order
        final answers = [
          FriendLanguage.words,
          FriendLanguage.words,
          FriendLanguage.acts,
          FriendLanguage.acts,
          FriendLanguage.gifts,
        ];

        // words comes first in enum, so it should win the tie
        expect(tallyQuizResults(answers), FriendLanguage.words);
      });

      test('quiz result metadata marks onboarding as complete', () {
        final profile = Profile(
          id: 'user-1',
          metadata: {'avatar_style': 'circle'},
        );

        final answered = [
          FriendLanguage.time,
          FriendLanguage.time,
          FriendLanguage.gifts,
          FriendLanguage.time,
          FriendLanguage.words,
        ];
        final result = tallyQuizResults(answered);

        final merged = <String, dynamic>{
          ...?profile.metadata,
          'friend_language': result.name,
          'onboarding_complete': true,
        };

        expect(merged['avatar_style'], 'circle');
        expect(merged['friend_language'], 'time');
        expect(merged['onboarding_complete'], true);
      });

      test('getFriendLanguage returns correct info', () {
        final info = getFriendLanguage(FriendLanguage.gifts);

        expect(info.label, 'Thoughtful Gifts');
        expect(info.symbol, '🎁');
        expect(info.description, isNotEmpty);
      });
    });

    group('Onboarding completion detection', () {
      test('empty metadata means onboarding not complete', () {
        final meta = <String, dynamic>{};
        final complete =
            meta['onboarding_complete'] == true ||
            meta['onboarding_complete'] == 'true' ||
            meta['friend_language'] != null;

        expect(complete, false);
      });

      test('onboarding_complete: true means complete', () {
        final Map<String, dynamic> meta = {'onboarding_complete': true};
        final complete =
            meta['onboarding_complete'] == true ||
            meta['onboarding_complete'] == 'true' ||
            meta['friend_language'] != null;

        expect(complete, true);
      });

      test('onboarding_complete: "true" (string) means complete', () {
        final Map<String, dynamic> meta = {'onboarding_complete': 'true'};
        final complete =
            meta['onboarding_complete'] == true ||
            meta['onboarding_complete'] == 'true' ||
            meta['friend_language'] != null;

        expect(complete, true);
      });

      test('friend_language presence means complete (legacy)', () {
        final Map<String, dynamic> meta = {'friend_language': 'gifts'};
        final complete =
            meta['onboarding_complete'] == true ||
            meta['onboarding_complete'] == 'true' ||
            meta['friend_language'] != null;

        expect(complete, true);
      });

      test('avatar metadata alone does NOT mean complete', () {
        final Map<String, dynamic> meta = {
          'avatar_style': 'circle',
          'avatar_eyes': 'happy',
        };
        final complete =
            meta['onboarding_complete'] == true ||
            meta['onboarding_complete'] == 'true' ||
            meta['friend_language'] != null;

        expect(complete, false);
      });

      test('null metadata means not complete', () {
        const Map<String, dynamic>? meta = null;
        final complete =
            meta != null &&
            (meta['onboarding_complete'] == true ||
                meta['onboarding_complete'] == 'true' ||
                meta['friend_language'] != null);

        expect(complete, false);
      });
    });
  });
}
