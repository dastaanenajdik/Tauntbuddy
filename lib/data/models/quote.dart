/// A motivational quote for the dashboard's "Daily inspiration" widget.
class Quote {
  const Quote({
    required this.text,
    this.author = 'TauntBuddy',
    this.category = 'focus',
  });

  final String text;
  final String author;
  final String category;

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        text: (json['text'] as String?) ?? '',
        author: (json['author'] as String?) ?? 'TauntBuddy',
        category: (json['category'] as String?) ?? 'focus',
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'text': text,
        'author': author,
        'category': category,
      };

  static const List<Quote> fallback = <Quote>[
    Quote(text: 'Ekagra ka matlab hai ek lakshya, ek samay, ek dhyan.', category: 'focus'),
    Quote(
      text: 'Kal karunga, ye sabse mehnga wada hai jo tu khud se karta hai.',
      category: 'procrastination',
    ),
    Quote(text: 'Focus ek muscle hai. Aaj 25 minute, kal 50.', category: 'focus'),
    Quote(text: 'Aaj ka 1% better, kal ka topper banata hai.', category: 'growth'),
  ];
}

/// A parsed quote file (`assets/data/quotes.json`).
class QuoteDataset {
  const QuoteDataset({required this.quotes, this.updatedAt, this.fromRemote = false});

  final List<Quote> quotes;
  final String? updatedAt;
  final bool fromRemote;

  bool get isEmpty => quotes.isEmpty;

  /// Stable pick per day so the dashboard quote does not shuffle on rebuild.
  Quote forDay(DateTime day) {
    if (quotes.isEmpty) return Quote.fallback.first;
    final int seed = day.year * 1000 + day.month * 40 + day.day;
    return quotes[seed % quotes.length];
  }

  factory QuoteDataset.fromJson(Map<String, dynamic> json, {bool fromRemote = false}) {
    final List<dynamic> raw = (json['quotes'] as List<dynamic>?) ?? const <dynamic>[];
    return QuoteDataset(
      updatedAt: json['updatedAt'] as String?,
      fromRemote: fromRemote,
      quotes: raw
          .whereType<Map<String, dynamic>>()
          .map(Quote.fromJson)
          .where((Quote q) => q.text.isNotEmpty)
          .toList(growable: false),
    );
  }
}
