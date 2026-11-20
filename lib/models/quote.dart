class Quote {
  final String id;
  final String text;
  final String author;
  final String category;

  const Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'author': author,
    'category': category,
  };

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
    id: json['id'] as String,
    text: json['text'] as String,
    author: json['author'] as String,
    category: json['category'] as String,
  );
}

const List<String> quoteCategories = [
  'All',
  'My Quotes',
  'Motivation',
  'Focus',
  'Wisdom',
  'Calm',
  'Learning',
  'Resilience',
];