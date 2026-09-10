class Author {
  final int id;
  final String firstName;
  final String lastName;
  final String country;
  final int birthYear;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.country,
    required this.birthYear,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      firstName: json['firstName'] is String ? json['firstName'] as String : '',
      lastName: json['lastName'] is String ? json['lastName'] as String : '',
      country: json['country'] is String ? json['country'] as String : '',
      birthYear: json['birthYear'] is num
          ? (json['birthYear'] as num).toInt()
          : 0,
      deletedAt: json['deletedAt'] is String
          ? DateTime.tryParse(json['deletedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'country': country,
    'birthYear': birthYear,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  // clearDeletedAt позволяет явно сбросить дату в null.
  Author copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? country,
    int? birthYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      country: country ?? this.country,
      birthYear: birthYear ?? this.birthYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
