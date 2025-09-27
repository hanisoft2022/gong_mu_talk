class PrefixTokenizer {
  const PrefixTokenizer({
    this.maxTokenLength = 20,
    this.maxTokensPerField = 50,
  });

  final int maxTokenLength;
  final int maxTokensPerField;

  List<String> buildPrefixes({
    String? title,
    String? body,
    Iterable<String>? tags,
  }) {
    final Set<String> tokens = <String>{};

    void addTokens(String? value) {
      if (value == null || value.trim().isEmpty) {
        return;
      }

      final List<String> words = value
          .toLowerCase()
          .split(RegExp(r'[\s.,!?@#\-_/]+'))
          .where((String word) => word.trim().isNotEmpty)
          .toList(growable: false);

      for (final String word in words) {
        final int limit = word.length.clamp(1, maxTokenLength);
        for (int i = 1; i <= limit; i += 1) {
          tokens.add(word.substring(0, i));
          if (tokens.length >= maxTokensPerField) {
            break;
          }
        }
        if (tokens.length >= maxTokensPerField) {
          break;
        }
      }
    }

    addTokens(title);
    addTokens(body);

    if (tags != null) {
      for (final String tag in tags) {
        addTokens(tag);
      }
    }

    return tokens.take(maxTokensPerField).toList(growable: false);
  }
}
