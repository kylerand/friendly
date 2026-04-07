/// Avatar System — Types & Configuration (Avataaars via DiceBear)
///
/// Uses the DiceBear "avataaars" style — the same visual design as the
/// popular Avataaars library by Pablo Stanley, but rendered as pure SVG.
///
/// Storage: serialised as flat string values inside the profile's
/// `metadata` JSONB column (prefixed with `avatar_`), so no migration
/// is needed.
library;

// ---------------------------------------------------------------------------
// Trait option helper
// ---------------------------------------------------------------------------

class TraitOption {
  final String key;
  final String label;
  final String? swatch;

  const TraitOption({required this.key, required this.label, this.swatch});
}

// ---------------------------------------------------------------------------
// Avatar configuration
// ---------------------------------------------------------------------------

class AvatarConfig {
  final String style;
  final String top;
  final String accessories;
  final String accessoriesColor;
  final String hairColor;
  final String facialHair;
  final String facialHairColor;
  final String clothing;
  final String clothesColor;
  final String clothingGraphic;
  final String eyebrows;
  final String eyes;
  final String mouth;
  final String skinColor;
  /// True when avatar was explicitly customised (has avatar_ metadata keys).
  final bool hasCustomConfig;

  const AvatarConfig({
    this.style = 'circle',
    this.top = 'shortFlat',
    this.accessories = 'none',
    this.accessoriesColor = '262e33',
    this.hairColor = '4a312c',
    this.facialHair = 'none',
    this.facialHairColor = '4a312c',
    this.clothing = 'shirtCrewNeck',
    this.clothesColor = '65c9ff',
    this.clothingGraphic = 'bear',
    this.eyebrows = 'default',
    this.eyes = 'default',
    this.mouth = 'smile',
    this.skinColor = 'edb98a',
    this.hasCustomConfig = false,
  });

  AvatarConfig copyWith({
    String? style,
    String? top,
    String? accessories,
    String? accessoriesColor,
    String? hairColor,
    String? facialHair,
    String? facialHairColor,
    String? clothing,
    String? clothesColor,
    String? clothingGraphic,
    String? eyebrows,
    String? eyes,
    String? mouth,
    String? skinColor,
    bool? hasCustomConfig,
  }) {
    return AvatarConfig(
      style: style ?? this.style,
      top: top ?? this.top,
      accessories: accessories ?? this.accessories,
      accessoriesColor: accessoriesColor ?? this.accessoriesColor,
      hairColor: hairColor ?? this.hairColor,
      facialHair: facialHair ?? this.facialHair,
      facialHairColor: facialHairColor ?? this.facialHairColor,
      clothing: clothing ?? this.clothing,
      clothesColor: clothesColor ?? this.clothesColor,
      clothingGraphic: clothingGraphic ?? this.clothingGraphic,
      eyebrows: eyebrows ?? this.eyebrows,
      eyes: eyes ?? this.eyes,
      mouth: mouth ?? this.mouth,
      skinColor: skinColor ?? this.skinColor,
      hasCustomConfig: hasCustomConfig ?? true,
    );
  }

  /// Pack into flat metadata string values (with `avatar_` prefix).
  Map<String, String> toMetadata() {
    return {
      '${_avatarPrefix}style': style,
      '${_avatarPrefix}top': top,
      '${_avatarPrefix}accessories': accessories,
      '${_avatarPrefix}accessoriesColor': accessoriesColor,
      '${_avatarPrefix}hairColor': hairColor,
      '${_avatarPrefix}facialHair': facialHair,
      '${_avatarPrefix}facialHairColor': facialHairColor,
      '${_avatarPrefix}clothing': clothing,
      '${_avatarPrefix}clothesColor': clothesColor,
      '${_avatarPrefix}clothingGraphic': clothingGraphic,
      '${_avatarPrefix}eyebrows': eyebrows,
      '${_avatarPrefix}eyes': eyes,
      '${_avatarPrefix}mouth': mouth,
      '${_avatarPrefix}skinColor': skinColor,
    };
  }

  /// Extract an AvatarConfig from profile metadata, falling back to defaults.
  factory AvatarConfig.fromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return const AvatarConfig();

    final hasAvatarKeys =
        metadata.keys.any((k) => k.startsWith(_avatarPrefix));
    if (!hasAvatarKeys) return const AvatarConfig();

    const def = AvatarConfig();
    return AvatarConfig(
      style: metadata['${_avatarPrefix}style'] as String? ?? def.style,
      top: metadata['${_avatarPrefix}top'] as String? ?? def.top,
      accessories:
          metadata['${_avatarPrefix}accessories'] as String? ?? def.accessories,
      accessoriesColor:
          metadata['${_avatarPrefix}accessoriesColor'] as String? ??
              def.accessoriesColor,
      hairColor:
          metadata['${_avatarPrefix}hairColor'] as String? ?? def.hairColor,
      facialHair:
          metadata['${_avatarPrefix}facialHair'] as String? ?? def.facialHair,
      facialHairColor:
          metadata['${_avatarPrefix}facialHairColor'] as String? ??
              def.facialHairColor,
      clothing:
          metadata['${_avatarPrefix}clothing'] as String? ?? def.clothing,
      clothesColor:
          metadata['${_avatarPrefix}clothesColor'] as String? ??
              def.clothesColor,
      clothingGraphic:
          metadata['${_avatarPrefix}clothingGraphic'] as String? ??
              def.clothingGraphic,
      eyebrows:
          metadata['${_avatarPrefix}eyebrows'] as String? ?? def.eyebrows,
      eyes: metadata['${_avatarPrefix}eyes'] as String? ?? def.eyes,
      mouth: metadata['${_avatarPrefix}mouth'] as String? ?? def.mouth,
      skinColor:
          metadata['${_avatarPrefix}skinColor'] as String? ?? def.skinColor,
      hasCustomConfig: true,
    );
  }

  static const _avatarPrefix = 'avatar_';
}

// ---------------------------------------------------------------------------
// Default avatar — warm and friendly out of the box
// ---------------------------------------------------------------------------

const defaultAvatar = AvatarConfig();

// ---------------------------------------------------------------------------
// Human-readable labels & swatch colours for the editor UI
// ---------------------------------------------------------------------------

const topOptions = <TraitOption>[
  TraitOption(key: 'bigHair', label: 'Big Hair'),
  TraitOption(key: 'bob', label: 'Bob'),
  TraitOption(key: 'bun', label: 'Bun'),
  TraitOption(key: 'curly', label: 'Curly'),
  TraitOption(key: 'curvy', label: 'Curvy'),
  TraitOption(key: 'dreads', label: 'Dreads'),
  TraitOption(key: 'dreads01', label: 'Dreads 2'),
  TraitOption(key: 'dreads02', label: 'Dreads 3'),
  TraitOption(key: 'frida', label: 'Frida'),
  TraitOption(key: 'frizzle', label: 'Frizzle'),
  TraitOption(key: 'fro', label: 'Fro'),
  TraitOption(key: 'froAndBand', label: 'Fro & Band'),
  TraitOption(key: 'miaWallace', label: 'Mia Wallace'),
  TraitOption(key: 'shaggy', label: 'Shaggy'),
  TraitOption(key: 'shavedSides', label: 'Shaved Sides'),
  TraitOption(key: 'shortCurly', label: 'Short Curly'),
  TraitOption(key: 'shortFlat', label: 'Short Flat'),
  TraitOption(key: 'shortRound', label: 'Short Round'),
  TraitOption(key: 'shortWaved', label: 'Short Waved'),
  TraitOption(key: 'sides', label: 'Sides'),
  TraitOption(key: 'straight01', label: 'Straight'),
  TraitOption(key: 'straight02', label: 'Straight 2'),
  TraitOption(key: 'straightAndStrand', label: 'Strand'),
  TraitOption(key: 'theCaesar', label: 'Caesar'),
  TraitOption(key: 'theCaesarAndSidePart', label: 'Caesar Side'),
  TraitOption(key: 'hat', label: 'Hat'),
  TraitOption(key: 'hijab', label: 'Hijab'),
  TraitOption(key: 'turban', label: 'Turban'),
  TraitOption(key: 'winterHat01', label: 'Beanie'),
  TraitOption(key: 'winterHat02', label: 'Beanie 2'),
  TraitOption(key: 'winterHat03', label: 'Beanie 3'),
  TraitOption(key: 'winterHat04', label: 'Beanie 4'),
];

const accessoriesOptions = <TraitOption>[
  TraitOption(key: 'none', label: 'None'),
  TraitOption(key: 'eyepatch', label: 'Eyepatch'),
  TraitOption(key: 'kurt', label: 'Kurt'),
  TraitOption(key: 'prescription01', label: 'Rx Glasses'),
  TraitOption(key: 'prescription02', label: 'Rx Glasses 2'),
  TraitOption(key: 'round', label: 'Round'),
  TraitOption(key: 'sunglasses', label: 'Sunglasses'),
  TraitOption(key: 'wayfarers', label: 'Wayfarers'),
];

const accessoriesColorOptions = <TraitOption>[
  TraitOption(key: '262e33', label: 'Black', swatch: '#262e33'),
  TraitOption(key: '3c4f5c', label: 'Slate', swatch: '#3c4f5c'),
  TraitOption(key: '929598', label: 'Gray', swatch: '#929598'),
  TraitOption(key: 'e6e6e6', label: 'Silver', swatch: '#e6e6e6'),
  TraitOption(key: 'ffffff', label: 'White', swatch: '#ffffff'),
  TraitOption(key: '65c9ff', label: 'Sky Blue', swatch: '#65c9ff'),
  TraitOption(key: 'b1e2ff', label: 'Light Blue', swatch: '#b1e2ff'),
  TraitOption(key: 'a7ffc4', label: 'Mint', swatch: '#a7ffc4'),
  TraitOption(key: 'ff5c5c', label: 'Red', swatch: '#ff5c5c'),
  TraitOption(key: 'ff488e', label: 'Hot Pink', swatch: '#ff488e'),
];

const hairColorOptions = <TraitOption>[
  TraitOption(key: '2c1b18', label: 'Black', swatch: '#2c1b18'),
  TraitOption(key: '4a312c', label: 'Dark Brown', swatch: '#4a312c'),
  TraitOption(key: '724133', label: 'Brown', swatch: '#724133'),
  TraitOption(key: 'a55728', label: 'Auburn', swatch: '#a55728'),
  TraitOption(key: 'b58143', label: 'Caramel', swatch: '#b58143'),
  TraitOption(key: 'c93305', label: 'Red', swatch: '#c93305'),
  TraitOption(key: 'd6b370', label: 'Blonde', swatch: '#d6b370'),
  TraitOption(key: 'e8e1e1', label: 'Platinum', swatch: '#e8e1e1'),
  TraitOption(key: 'ecdcbf', label: 'Sandy', swatch: '#ecdcbf'),
  TraitOption(key: 'f59797', label: 'Pink', swatch: '#f59797'),
];

const facialHairOptions = <TraitOption>[
  TraitOption(key: 'none', label: 'None'),
  TraitOption(key: 'beardLight', label: 'Light Beard'),
  TraitOption(key: 'beardMajestic', label: 'Majestic'),
  TraitOption(key: 'beardMedium', label: 'Medium Beard'),
  TraitOption(key: 'moustacheFancy', label: 'Fancy Stache'),
  TraitOption(key: 'moustacheMagnum', label: 'Magnum'),
];

const facialHairColorOptions = <TraitOption>[
  TraitOption(key: '2c1b18', label: 'Black', swatch: '#2c1b18'),
  TraitOption(key: '4a312c', label: 'Dark Brown', swatch: '#4a312c'),
  TraitOption(key: '724133', label: 'Brown', swatch: '#724133'),
  TraitOption(key: 'a55728', label: 'Auburn', swatch: '#a55728'),
  TraitOption(key: 'b58143', label: 'Caramel', swatch: '#b58143'),
  TraitOption(key: 'c93305', label: 'Red', swatch: '#c93305'),
  TraitOption(key: 'd6b370', label: 'Blonde', swatch: '#d6b370'),
  TraitOption(key: 'e8e1e1', label: 'Platinum', swatch: '#e8e1e1'),
  TraitOption(key: 'ecdcbf', label: 'Sandy', swatch: '#ecdcbf'),
  TraitOption(key: 'f59797', label: 'Pink', swatch: '#f59797'),
];

const clothingOptions = <TraitOption>[
  TraitOption(key: 'blazerAndShirt', label: 'Blazer Shirt'),
  TraitOption(key: 'blazerAndSweater', label: 'Blazer Sweater'),
  TraitOption(key: 'collarAndSweater', label: 'Collar Sweater'),
  TraitOption(key: 'graphicShirt', label: 'Graphic Tee'),
  TraitOption(key: 'hoodie', label: 'Hoodie'),
  TraitOption(key: 'overall', label: 'Overall'),
  TraitOption(key: 'shirtCrewNeck', label: 'Crew Neck'),
  TraitOption(key: 'shirtScoopNeck', label: 'Scoop Neck'),
  TraitOption(key: 'shirtVNeck', label: 'V-Neck'),
];

const clothesColorOptions = <TraitOption>[
  TraitOption(key: '262e33', label: 'Charcoal', swatch: '#262e33'),
  TraitOption(key: '3c4f5c', label: 'Slate', swatch: '#3c4f5c'),
  TraitOption(key: '25557c', label: 'Navy', swatch: '#25557c'),
  TraitOption(key: '5199e4', label: 'Blue', swatch: '#5199e4'),
  TraitOption(key: '65c9ff', label: 'Sky Blue', swatch: '#65c9ff'),
  TraitOption(key: 'b1e2ff', label: 'Light Blue', swatch: '#b1e2ff'),
  TraitOption(key: '929598', label: 'Gray', swatch: '#929598'),
  TraitOption(key: 'e6e6e6', label: 'Light Gray', swatch: '#e6e6e6'),
  TraitOption(key: 'ffffff', label: 'White', swatch: '#ffffff'),
  TraitOption(key: 'a7ffc4', label: 'Mint', swatch: '#a7ffc4'),
  TraitOption(key: 'ffdeb5', label: 'Peach', swatch: '#ffdeb5'),
  TraitOption(key: 'ffffb1', label: 'Cream', swatch: '#ffffb1'),
  TraitOption(key: 'ffafb9', label: 'Pink', swatch: '#ffafb9'),
  TraitOption(key: 'ff488e', label: 'Hot Pink', swatch: '#ff488e'),
  TraitOption(key: 'ff5c5c', label: 'Red', swatch: '#ff5c5c'),
];

const clothingGraphicOptions = <TraitOption>[
  TraitOption(key: 'bunny', label: 'Friendly Bunny'),
  TraitOption(key: 'bat', label: 'Bat'),
  TraitOption(key: 'bear', label: 'Bear'),
  TraitOption(key: 'cumbia', label: 'Cumbia'),
  TraitOption(key: 'deer', label: 'Deer'),
  TraitOption(key: 'diamond', label: 'Diamond'),
  TraitOption(key: 'hola', label: 'Hola'),
  TraitOption(key: 'pizza', label: 'Pizza'),
  TraitOption(key: 'resist', label: 'Resist'),
  TraitOption(key: 'skull', label: 'Skull'),
  TraitOption(key: 'skullOutline', label: 'Skull Outline'),
];

const eyebrowOptions = <TraitOption>[
  TraitOption(key: 'default', label: 'Default'),
  TraitOption(key: 'defaultNatural', label: 'Natural'),
  TraitOption(key: 'flatNatural', label: 'Flat'),
  TraitOption(key: 'frownNatural', label: 'Frown'),
  TraitOption(key: 'raisedExcited', label: 'Raised'),
  TraitOption(key: 'raisedExcitedNatural', label: 'Raised Natural'),
  TraitOption(key: 'sadConcerned', label: 'Sad'),
  TraitOption(key: 'sadConcernedNatural', label: 'Sad Natural'),
  TraitOption(key: 'unibrowNatural', label: 'Unibrow'),
  TraitOption(key: 'upDown', label: 'Up Down'),
  TraitOption(key: 'upDownNatural', label: 'Up Down Natural'),
  TraitOption(key: 'angry', label: 'Angry'),
  TraitOption(key: 'angryNatural', label: 'Angry Natural'),
];

const eyeOptions = <TraitOption>[
  TraitOption(key: 'default', label: 'Default'),
  TraitOption(key: 'happy', label: 'Happy'),
  TraitOption(key: 'closed', label: 'Closed'),
  TraitOption(key: 'cry', label: 'Cry'),
  TraitOption(key: 'eyeRoll', label: 'Eye Roll'),
  TraitOption(key: 'hearts', label: 'Hearts'),
  TraitOption(key: 'side', label: 'Side'),
  TraitOption(key: 'squint', label: 'Squint'),
  TraitOption(key: 'surprised', label: 'Surprised'),
  TraitOption(key: 'wink', label: 'Wink'),
  TraitOption(key: 'winkWacky', label: 'Wink Wacky'),
  TraitOption(key: 'xDizzy', label: 'Dizzy'),
];

const mouthOptions = <TraitOption>[
  TraitOption(key: 'default', label: 'Default'),
  TraitOption(key: 'smile', label: 'Smile'),
  TraitOption(key: 'twinkle', label: 'Twinkle'),
  TraitOption(key: 'tongue', label: 'Tongue'),
  TraitOption(key: 'eating', label: 'Eating'),
  TraitOption(key: 'grimace', label: 'Grimace'),
  TraitOption(key: 'sad', label: 'Sad'),
  TraitOption(key: 'serious', label: 'Serious'),
  TraitOption(key: 'screamOpen', label: 'Scream'),
  TraitOption(key: 'concerned', label: 'Concerned'),
  TraitOption(key: 'disbelief', label: 'Disbelief'),
  TraitOption(key: 'vomit', label: 'Vomit'),
];

const skinColorOptions = <TraitOption>[
  TraitOption(key: 'ffdbb4', label: 'Light', swatch: '#ffdbb4'),
  TraitOption(key: 'edb98a', label: 'Fair', swatch: '#edb98a'),
  TraitOption(key: 'f8d25c', label: 'Yellow', swatch: '#f8d25c'),
  TraitOption(key: 'fd9841', label: 'Amber', swatch: '#fd9841'),
  TraitOption(key: 'd08b5b', label: 'Medium', swatch: '#d08b5b'),
  TraitOption(key: 'ae5d29', label: 'Brown', swatch: '#ae5d29'),
  TraitOption(key: '614335', label: 'Dark', swatch: '#614335'),
];

const styleOptions = <TraitOption>[
  TraitOption(key: 'circle', label: 'Circle'),
  TraitOption(key: 'default', label: 'No BG'),
];
