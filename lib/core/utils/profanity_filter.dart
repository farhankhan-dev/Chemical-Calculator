class ProfanityFilter {
  static const List<String> _bannedWords = [
    'fuck',
    'shit',
    'bitch',
    'ass',
    'cunt',
    'dick',
    'pussy',
    'whore',
    'slut',
    'bastard',
    'sameer', // User specifically complained about this friend name
    'sam',
  ];

  static bool containsBannedWord(String input) {
    final lowerInput = input.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    for (final word in _bannedWords) {
      if (lowerInput.contains(word)) {
        return true;
      }
    }
    return false;
  }
}
