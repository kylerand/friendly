import 'package:flutter_test/flutter_test.dart';
import 'package:friendly/components/avatar/avatar_types.dart';

void main() {
  group('AvatarConfig', () {
    test('default config has expected values', () {
      const config = AvatarConfig();
      expect(config.style, 'circle');
      expect(config.top, 'shortFlat');
      expect(config.eyes, 'default');
      expect(config.mouth, 'smile');
      expect(config.hasCustomConfig, false);
    });

    test('toMetadata produces avatar_-prefixed keys', () {
      const config = AvatarConfig();
      final meta = config.toMetadata();

      expect(meta['avatar_style'], 'circle');
      expect(meta['avatar_top'], 'shortFlat');
      expect(meta['avatar_eyes'], 'default');
      expect(meta['avatar_mouth'], 'smile');
      expect(meta['avatar_skinColor'], 'edb98a');
      // All keys should be avatar-prefixed
      for (final key in meta.keys) {
        expect(key.startsWith('avatar_'), true,
            reason: 'Key "$key" should be prefixed with avatar_');
      }
    });

    test('fromMetadata round-trips through toMetadata', () {
      const original = AvatarConfig(
        style: 'default',
        top: 'curly',
        eyes: 'happy',
        mouth: 'tongue',
        skinColor: 'ffdbb4',
      );

      final metadata = original.toMetadata();
      final restored = AvatarConfig.fromMetadata(metadata);

      expect(restored.style, original.style);
      expect(restored.top, original.top);
      expect(restored.eyes, original.eyes);
      expect(restored.mouth, original.mouth);
      expect(restored.skinColor, original.skinColor);
      expect(restored.hasCustomConfig, true);
    });

    test('fromMetadata with null returns default config', () {
      final config = AvatarConfig.fromMetadata(null);
      expect(config.style, 'circle');
      expect(config.hasCustomConfig, false);
    });

    test('fromMetadata with no avatar_ keys returns default config', () {
      final config = AvatarConfig.fromMetadata({
        'onboarding_complete': true,
        'friend_language': 'gifts',
      });
      expect(config.style, 'circle');
      expect(config.hasCustomConfig, false);
    });

    test('copyWith preserves unmodified fields', () {
      const config = AvatarConfig(style: 'circle', eyes: 'default');
      final modified = config.copyWith(eyes: 'happy');

      expect(modified.style, 'circle');
      expect(modified.eyes, 'happy');
      expect(modified.hasCustomConfig, true);
    });

    test('copyWith can update hasCustomConfig', () {
      const config = AvatarConfig();
      expect(config.hasCustomConfig, false);

      final customised = config.copyWith(hasCustomConfig: true);
      expect(customised.hasCustomConfig, true);
    });

    test('toMetadata can be merged with existing profile metadata', () {
      // Simulates the pattern used in _saveAvatarAndContinue
      final existingMeta = <String, dynamic>{
        'some_key': 'some_value',
      };

      const avatarConfig = AvatarConfig(style: 'default', eyes: 'wink');
      final merged = <String, dynamic>{
        ...existingMeta,
        ...avatarConfig.toMetadata(),
      };

      expect(merged['some_key'], 'some_value');
      expect(merged['avatar_style'], 'default');
      expect(merged['avatar_eyes'], 'wink');
    });

    test('toMetadata merges with null metadata safely', () {
      // Simulates the pattern for a brand new user with no metadata
      const Map<String, dynamic>? nullMeta = null;
      const avatarConfig = AvatarConfig();

      final merged = <String, dynamic>{
        ...?nullMeta,
        ...avatarConfig.toMetadata(),
      };

      expect(merged.containsKey('avatar_style'), true);
      expect(merged['avatar_style'], 'circle');
    });
  });

  group('Trait options', () {
    test('styleOptions has expected entries', () {
      expect(styleOptions.length, 2);
      expect(styleOptions.map((o) => o.key), contains('circle'));
      expect(styleOptions.map((o) => o.key), contains('default'));
    });

    test('all option lists are non-empty', () {
      expect(topOptions, isNotEmpty);
      expect(hairColorOptions, isNotEmpty);
      expect(eyeOptions, isNotEmpty);
      expect(eyebrowOptions, isNotEmpty);
      expect(mouthOptions, isNotEmpty);
      expect(facialHairOptions, isNotEmpty);
      expect(facialHairColorOptions, isNotEmpty);
      expect(accessoriesOptions, isNotEmpty);
      expect(accessoriesColorOptions, isNotEmpty);
      expect(clothingOptions, isNotEmpty);
      expect(clothesColorOptions, isNotEmpty);
      expect(clothingGraphicOptions, isNotEmpty);
      expect(skinColorOptions, isNotEmpty);
    });

    test('color options have valid hex swatch values', () {
      for (final opt in hairColorOptions) {
        expect(opt.swatch, isNotNull);
        expect(opt.swatch!.startsWith('#'), true);
        // Should be a valid 6-char hex after #
        final hex = opt.swatch!.replaceFirst('#', '');
        expect(hex.length, 6);
        expect(int.tryParse('FF$hex', radix: 16), isNotNull,
            reason: 'Invalid hex color: ${opt.swatch}');
      }
    });
  });
}
