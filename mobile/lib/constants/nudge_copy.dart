enum WarmthTier { radiant, warm, gentle, quiet }

class WarmthTierInfo {
  final WarmthTier tier;
  final String label;
  final String emoji;
  final String tagline;
  final String description;

  const WarmthTierInfo({
    required this.tier,
    required this.label,
    required this.emoji,
    required this.tagline,
    required this.description,
  });
}

const warmthTiers = <WarmthTier, WarmthTierInfo>{
  WarmthTier.radiant: WarmthTierInfo(
    tier: WarmthTier.radiant,
    label: 'Radiant',
    emoji: '☀️',
    tagline: "You're on fire!",
    description:
        "You've been consistently reaching out. Your friendships are thriving.",
  ),
  WarmthTier.warm: WarmthTierInfo(
    tier: WarmthTier.warm,
    label: 'Warm',
    emoji: '🔥',
    tagline: 'Feeling good',
    description: "You're keeping in touch regularly. Keep it up!",
  ),
  WarmthTier.gentle: WarmthTierInfo(
    tier: WarmthTier.gentle,
    label: 'Gentle',
    emoji: '🕯️',
    tagline: 'A little quiet',
    description:
        "It's been a bit since you reached out. A quick hello could brighten someone's day.",
  ),
  WarmthTier.quiet: WarmthTierInfo(
    tier: WarmthTier.quiet,
    label: 'Quiet',
    emoji: '❄️',
    tagline: 'Time to reconnect',
    description:
        'Your friendships could use some warmth. Even a small gesture goes a long way.',
  ),
};
