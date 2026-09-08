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
