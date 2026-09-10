class Book {
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int publisherId;
  final List<int> authorIds;
  final List<int> genreIds;
  final int copiesTotal;
  final int copiesAvailable;
  final DateTime? deletedAt;

  const Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.year,
    required this.pages,
    required this.publisherId,
    required this.authorIds,
    required this.genreIds,
    required this.copiesTotal,
    required this.copiesAvailable,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      title: json['title'] is String ? json['title'] as String : '',
      isbn: json['isbn'] is String ? json['isbn'] as String : '',
      year: json['year'] is num ? (json['year'] as num).toInt() : 0,
      pages: json['pages'] is num ? (json['pages'] as num).toInt() : 0,
      publisherId: json['publisherId'] is num
          ? (json['publisherId'] as num).toInt()
          : 0,
      authorIds: json['authorIds'] is List
          ? (json['authorIds'] as List)
                .whereType<num>()
                .map((id) => id.toInt())
                .toList()
          : <int>[],
      genreIds: json['genreIds'] is List
          ? (json['genreIds'] as List)
                .whereType<num>()
                .map((id) => id.toInt())
                .toList()
          : <int>[],
      copiesTotal: json['copiesTotal'] is num
          ? (json['copiesTotal'] as num).toInt()
          : 0,
      copiesAvailable: json['copiesAvailable'] is num
          ? (json['copiesAvailable'] as num).toInt()
          : 0,
      deletedAt: json['deletedAt'] is String
          ? DateTime.tryParse(json['deletedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isbn': isbn,
    'year': year,
    'pages': pages,
    'publisherId': publisherId,
    'authorIds': authorIds,
    'genreIds': genreIds,
    'copiesTotal': copiesTotal,
    'copiesAvailable': copiesAvailable,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  // clearDeletedAt позволяет явно сбросить дату в null.
  Book copyWith({
    int? id,
    String? title,
    String? isbn,
    int? year,
    int? pages,
    int? publisherId,
    List<int>? authorIds,
    List<int>? genreIds,
    int? copiesTotal,
    int? copiesAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      isbn: isbn ?? this.isbn,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      publisherId: publisherId ?? this.publisherId,
      authorIds: authorIds ?? this.authorIds,
      genreIds: genreIds ?? this.genreIds,
      copiesTotal: copiesTotal ?? this.copiesTotal,
      copiesAvailable: copiesAvailable ?? this.copiesAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
