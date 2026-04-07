enum FriendLanguage { words, acts, gifts, time, touch }

class FriendLanguageInfo {
  final FriendLanguage key;
  final String label;
  final String symbol;
  final String description;
  final List<String> examples;

  const FriendLanguageInfo({
    required this.key,
    required this.label,
    required this.symbol,
    required this.description,
    required this.examples,
  });
}

const languages = <FriendLanguage, FriendLanguageInfo>{
  FriendLanguage.words: FriendLanguageInfo(
    key: FriendLanguage.words,
    label: 'Words of Affirmation',
    symbol: '💬',
    description:
        'You feel most connected when friends express how much you mean to them — a heartfelt text, a genuine compliment, or words of encouragement.',
    examples: [
      'A voice memo saying "I\'m proud of you"',
      'A random "I appreciate you" text',
      'Encouraging words before a big day',
    ],
  ),
  FriendLanguage.acts: FriendLanguageInfo(
    key: FriendLanguage.acts,
    label: 'Acts of Service',
    symbol: '🤲',
    description:
        'Nothing says "I care" like a friend who shows up. You value actions over words — the friend who helps you move, picks you up from the airport, or drops off soup when you\'re sick.',
    examples: [
      'Helping with a move without being asked',
      'Running an errand when you\'re overwhelmed',
      'Making plans so you don\'t have to',
    ],
  ),
  FriendLanguage.gifts: FriendLanguageInfo(
    key: FriendLanguage.gifts,
    label: 'Thoughtful Gifts',
    symbol: '🎁',
    description:
        'It\'s not about price — it\'s that someone saw something and thought of you. A meme, a book recommendation, a snack you love. The gift IS the thought.',
    examples: [
      '"This reminded me of you" texts with a link',
      'A small surprise on a tough day',
      'Remembering your favourite snack',
    ],
  ),
  FriendLanguage.time: FriendLanguageInfo(
    key: FriendLanguage.time,
    label: 'Quality Time',
    symbol: '⏳',
    description:
        'Presence is your love language. You thrive on undivided attention — long dinners, walks with no agenda, or even just comfortable silence on a call.',
    examples: [
      'A phone call just to catch up',
      'An unplanned afternoon together',
      'Sitting together even when there\'s nothing to say',
    ],
  ),
  FriendLanguage.touch: FriendLanguageInfo(
    key: FriendLanguage.touch,
    label: 'Physical Presence',
    symbol: '🫂',
    description:
        'You connect through closeness — a hug when you arrive, sitting shoulder-to-shoulder, or a pat on the back that says "I\'m here."',
    examples: [
      'A long hug hello',
      'Walking arm-in-arm',
      'A reassuring hand on the shoulder',
    ],
  ),
};

class QuizOption {
  final String text;
  final FriendLanguage language;

  const QuizOption({required this.text, required this.language});
}

class QuizQuestion {
  final String question;
  final List<QuizOption> options;

  const QuizQuestion({required this.question, required this.options});
}

const quizQuestions = <QuizQuestion>[
  QuizQuestion(
    question: 'Your friend just got some tough news. What feels most natural?',
    options: [
      QuizOption(
        text:
            'Send a heartfelt message telling them how much they mean to you',
        language: FriendLanguage.words,
      ),
      QuizOption(
        text: 'Drop everything and go help them with whatever they need',
        language: FriendLanguage.acts,
      ),
      QuizOption(
        text: 'Send them a care package or their favourite comfort food',
        language: FriendLanguage.gifts,
      ),
      QuizOption(
        text: 'Clear your schedule and spend the day with them',
        language: FriendLanguage.time,
      ),
      QuizOption(
        text: 'Give them a big hug and just be physically present',
        language: FriendLanguage.touch,
      ),
    ],
  ),
  QuizQuestion(
    question:
        "It's your friend's birthday. What makes you most excited to do?",
    options: [
      QuizOption(
        text: 'Write them a meaningful card or message',
        language: FriendLanguage.words,
      ),
      QuizOption(
        text: 'Plan and organise the whole celebration',
        language: FriendLanguage.acts,
      ),
      QuizOption(
        text: 'Find the perfect, thoughtful gift',
        language: FriendLanguage.gifts,
      ),
      QuizOption(
        text: 'Dedicate the whole day to hanging out together',
        language: FriendLanguage.time,
      ),
      QuizOption(
        text: 'Celebrate with lots of hugs and high-fives',
        language: FriendLanguage.touch,
      ),
    ],
  ),
  QuizQuestion(
    question:
        "You haven't seen a friend in a while. How do you reconnect?",
    options: [
      QuizOption(
        text: 'Send a long, catch-up message or voice note',
        language: FriendLanguage.words,
      ),
      QuizOption(
        text:
            "Offer to help them with something they've been putting off",
        language: FriendLanguage.acts,
      ),
      QuizOption(
        text: 'Send them something that reminded you of them',
        language: FriendLanguage.gifts,
      ),
      QuizOption(
        text: 'Suggest an unhurried hang — coffee, walk, whatever',
        language: FriendLanguage.time,
      ),
      QuizOption(
        text: 'Show up and give them the biggest hug',
        language: FriendLanguage.touch,
      ),
    ],
  ),
  QuizQuestion(
    question:
        'A friend is celebrating a big win. How do you show you care?',
    options: [
      QuizOption(
        text: "Tell them specifically why you're proud of them",
        language: FriendLanguage.words,
      ),
      QuizOption(
        text: 'Help them prepare or celebrate — the logistics matter',
        language: FriendLanguage.acts,
      ),
      QuizOption(
        text: 'Surprise them with a meaningful gift or treat',
        language: FriendLanguage.gifts,
      ),
      QuizOption(
        text: 'Take them out to celebrate, just the two of you',
        language: FriendLanguage.time,
      ),
      QuizOption(
        text: 'Pick them up in a bear hug and celebrate physically',
        language: FriendLanguage.touch,
      ),
    ],
  ),
  QuizQuestion(
    question:
        "You're going through a rough patch. What would help most?",
    options: [
      QuizOption(
        text: "A friend texting 'I believe in you, here's why…'",
        language: FriendLanguage.words,
      ),
      QuizOption(
        text: 'A friend quietly taking something off your plate',
        language: FriendLanguage.acts,
      ),
      QuizOption(
        text: 'A friend dropping off your favourite treat with a note',
        language: FriendLanguage.gifts,
      ),
      QuizOption(
        text: 'A friend clearing their evening to be with you',
        language: FriendLanguage.time,
      ),
      QuizOption(
        text: 'A friend sitting close, arm around you, no words needed',
        language: FriendLanguage.touch,
      ),
    ],
  ),
];

/// Counts occurrences of each [FriendLanguage] and returns the most common.
/// Ties are broken by enum declaration order (first wins).
FriendLanguage tallyQuizResults(List<FriendLanguage> answers) {
  final counts = <FriendLanguage, int>{};
  for (final lang in FriendLanguage.values) {
    counts[lang] = 0;
  }
  for (final answer in answers) {
    counts[answer] = counts[answer]! + 1;
  }

  FriendLanguage winner = FriendLanguage.values.first;
  int maxCount = 0;
  for (final lang in FriendLanguage.values) {
    if (counts[lang]! > maxCount) {
      maxCount = counts[lang]!;
      winner = lang;
    }
  }
  return winner;
}

/// Returns the [FriendLanguageInfo] for a given [FriendLanguage].
FriendLanguageInfo getFriendLanguage(FriendLanguage key) {
  return languages[key]!;
}
