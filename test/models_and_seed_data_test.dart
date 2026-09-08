import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/repositories/seed_data.dart';

void main() {
  test('Начальные данные имеют уникальные ID и корректные связи', () {
    expect(seedBooks.length, greaterThanOrEqualTo(20));
    expect(seedAuthors.length, greaterThanOrEqualTo(8));

    final authorIds = seedAuthors.map((author) => author.id).toSet();
    expect(authorIds.length, seedAuthors.length);
    expect(seedBooks.map((book) => book.id).toSet().length, seedBooks.length);
    expect(seedBooks.map((book) => book.isbn).toSet().length, seedBooks.length);

    for (final book in seedBooks) {
      expect(book.authorIds, isNotEmpty);
      expect(book.genreIds, isNotEmpty);
      expect(book.authorIds.every(authorIds.contains), isTrue);
      expect(book.genreIds.every(seedGenres.containsKey), isTrue);
      expect(seedPublishers.containsKey(book.publisherId), isTrue);
      expect(book.pages, greaterThan(0));
      expect(book.copiesAvailable, inInclusiveRange(0, book.copiesTotal));
      expect(book.isDeleted, isFalse);
    }

    expect(seedAuthors.every((author) => !author.isDeleted), isTrue);
    expect(seedBooks.map((book) => book.year).toSet().length, greaterThan(1));
    expect(
      seedAuthors.map((author) => author.country).toSet().length,
      greaterThan(1),
    );
  });

  test('Book.copyWith обновляет поля и сохраняет оригинал', () {
    final original = seedBooks.first;
    final date = DateTime(2026, 9, 8);
    final updated = original.copyWith(
      id: 100,
      title: 'Другая книга',
      isbn: '9780000001007',
      year: 2026,
      pages: 500,
      publisherId: 4,
      authorIds: [2, 3],
      genreIds: [3, 4],
      copiesTotal: 10,
      copiesAvailable: 0,
      deletedAt: date,
    );

    expect(updated.id, 100);
    expect(updated.title, 'Другая книга');
    expect(updated.isbn, '9780000001007');
    expect(updated.year, 2026);
    expect(updated.pages, 500);
    expect(updated.publisherId, 4);
    expect(updated.authorIds, [2, 3]);
    expect(updated.genreIds, [3, 4]);
    expect(updated.copiesTotal, 10);
    expect(updated.copiesAvailable, 0);
    expect(updated.isDeleted, isTrue);
    expect(updated.copyWith().deletedAt, date);
    expect(updated.copyWith(clearDeletedAt: true).deletedAt, isNull);
    expect(updated.copyWith(clearDeletedAt: true).isDeleted, isFalse);
    expect(original.id, 1);
    expect(original.title, 'Дом у реки');
    expect(original.isDeleted, isFalse);

    final copy = original.copyWith();
    expect(copy.id, original.id);
    expect(copy.title, original.title);
    expect(copy.isbn, original.isbn);
    expect(copy.year, original.year);
    expect(copy.pages, original.pages);
    expect(copy.publisherId, original.publisherId);
    expect(copy.authorIds, original.authorIds);
    expect(copy.genreIds, original.genreIds);
    expect(copy.copiesTotal, original.copiesTotal);
    expect(copy.copiesAvailable, original.copiesAvailable);
  });

  test('Author.copyWith обновляет поля и сохраняет оригинал', () {
    final original = seedAuthors.first;
    final date = DateTime(2026, 9, 8);
    final updated = original.copyWith(
      id: 100,
      firstName: 'Пётр',
      lastName: 'Иванов',
      country: 'Беларусь',
      birthYear: 1991,
      deletedAt: date,
    );

    expect(updated.id, 100);
    expect(updated.firstName, 'Пётр');
    expect(updated.lastName, 'Иванов');
    expect(updated.country, 'Беларусь');
    expect(updated.birthYear, 1991);
    expect(updated.isDeleted, isTrue);
    expect(updated.copyWith().deletedAt, date);
    expect(updated.copyWith(clearDeletedAt: true).deletedAt, isNull);
    expect(updated.copyWith(clearDeletedAt: true).isDeleted, isFalse);
    expect(original.id, 1);
    expect(original.firstName, 'Иван');
    expect(original.isDeleted, isFalse);

    final copy = original.copyWith();
    expect(copy.id, original.id);
    expect(copy.firstName, original.firstName);
    expect(copy.lastName, original.lastName);
    expect(copy.country, original.country);
    expect(copy.birthYear, original.birthYear);
  });
}
