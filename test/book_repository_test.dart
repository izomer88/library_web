import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/repositories/book_repository.dart';
import 'package:library_web/repositories/in_memory_book_repository.dart';
import 'package:library_web/repositories/seed_data.dart';

void main() {
  late BookRepository repository;

  setUp(() {
    repository = InMemoryBookRepository();
  });

  test('Список и получение по ID', () {
    expect(repository.getAll().length, seedBooks.length);
    expect(repository.getById(1)?.id, 1);
    expect(repository.getById(-1), isNull);
    expect(repository.getAll(query: 'несуществующий текст'), isEmpty);
    expect(repository.getAll(query: '   ').length, seedBooks.length);
  });

  test('Логическое удаление ставит текущее время и скрывает запись', () {
    final before = DateTime.now();
    repository.softDelete(1);
    final after = DateTime.now();
    expect(repository.getById(1), isNull);
    expect(repository.getAll().any((item) => item.id == 1), isFalse);
    final deleted = repository.getById(1, includeDeleted: true)!;
    expect(deleted.isDeleted, isTrue);
    expect(deleted.deletedAt!.isBefore(before), isFalse);
    expect(deleted.deletedAt!.isAfter(after), isFalse);
    expect(repository.getAll(includeDeleted: true).length, seedBooks.length);
    expect(
      repository.getAll(includeDeleted: true).any((item) => item.id == 1),
      isTrue,
    );
  });

  test('Восстановление сбрасывает deletedAt', () {
    repository.softDelete(1);
    repository.restore(1);
    expect(repository.getById(1)?.deletedAt, isNull);
    expect(repository.getById(1)?.isDeleted, isFalse);
    expect(repository.getAll().length, seedBooks.length);
  });

  test('Физически удалённую запись нельзя восстановить', () {
    repository.softDelete(1);
    repository.hardDelete(1);
    repository.hardDelete(2);
    repository.restore(1);
    expect(repository.getById(1, includeDeleted: true), isNull);
    expect(repository.getById(2, includeDeleted: true), isNull);
    expect(
      repository.getAll(includeDeleted: true).length,
      seedBooks.length - 2,
    );
  });

  test('Неизвестные ID и повторные операции безопасны', () {
    repository.softDelete(-1);
    repository.hardDelete(-1);
    repository.restore(-1);
    repository.restore(1);
    repository.softDelete(1);
    repository.softDelete(1);
    repository.restore(1);
    repository.restore(1);
    expect(repository.getAll().length, seedBooks.length);
    repository.hardDelete(1);
    repository.hardDelete(1);
    expect(repository.getAll().length, seedBooks.length - 1);
  });

  test('Изменения изолированы от seed и других экземпляров', () {
    repository.softDelete(1);
    repository.hardDelete(2);
    repository.getAll().clear();
    final other = InMemoryBookRepository();
    expect(seedBooks.first.isDeleted, isFalse);
    expect(seedBooks.any((item) => item.id == 2), isTrue);
    expect(other.getAll().length, seedBooks.length);
    expect(repository.getAll().length, seedBooks.length - 2);
  });

  test('Поиск по части названия без учёта регистра и с пробелами', () {
    expect(repository.getAll(query: '  дОМ У РЕ  ').map((book) => book.id), [
      1,
    ]);
  });

  test('Поиск по ISBN и его части', () {
    expect(
      repository.getAll(query: seedBooks.first.isbn).map((book) => book.id),
      [1],
    );
    expect(repository.getAll(query: '0000019').map((book) => book.id), [1, 19]);
  });

  test('Поиск и все фильтры работают одновременно, включая удалённые', () {
    repository.softDelete(6);
    expect(
      repository.getAll(
        query: 'ГОРОД',
        genreId: 4,
        publisherId: 4,
        yearFrom: 2023,
        yearTo: 2023,
      ),
      isEmpty,
    );
    expect(
      repository
          .getAll(
            query: 'ГОРОД',
            genreId: 4,
            publisherId: 4,
            yearFrom: 2023,
            yearTo: 2023,
            includeDeleted: true,
          )
          .map((book) => book.id),
      [6],
    );
    repository.restore(6);
    expect(
      repository
          .getAll(
            query: 'ГОРОД',
            genreId: 4,
            publisherId: 4,
            yearFrom: 2023,
            yearTo: 2023,
          )
          .map((book) => book.id),
      [6],
    );
    expect(
      repository.getAll(
        query: 'ГОРОД',
        genreId: 1,
        publisherId: 4,
        yearFrom: 2023,
        yearTo: 2023,
      ),
      isEmpty,
    );
    expect(
      repository.getAll(
        query: 'ГОРОД',
        genreId: 4,
        publisherId: 1,
        yearFrom: 2023,
        yearTo: 2023,
      ),
      isEmpty,
    );
  });

  test('Фильтры жанра и издательства работают отдельно', () {
    expect(repository.getAll(genreId: 3).map((book) => book.id), [4, 5, 6, 9]);
    expect(repository.getAll(publisherId: 4).map((book) => book.id), [
      6,
      8,
      12,
      16,
      20,
    ]);
    expect(repository.getAll(genreId: -1), isEmpty);
    expect(repository.getAll(publisherId: -1), isEmpty);
  });

  test('Диапазон годов включает границы и поддерживает одну границу', () {
    expect(repository.getAll(yearFrom: 2023).map((book) => book.id), [
      6,
      19,
      20,
    ]);
    expect(repository.getAll(yearTo: 1998).map((book) => book.id), [1, 7]);
    expect(
      repository.getAll(yearFrom: 1998, yearTo: 2001).map((book) => book.id),
      [1, 10, 16],
    );
    expect(repository.getAll(yearFrom: 2025, yearTo: 1990), isEmpty);
  });

  test('deleteMany удаляет по ID, учитывает дубликаты и отсутствующие ID', () {
    repository.softDelete(2);
    expect(repository.deleteMany([1, 2, 3, 20, 2, -1]), 4);
    final remaining = repository
        .getAll(includeDeleted: true)
        .map((book) => book.id);
    expect(remaining, List.generate(16, (index) => index + 4));
    expect(repository.deleteMany([1, 2, -1]), 0);
    expect(repository.deleteMany([]), 0);
    repository.restore(2);
    expect(repository.getById(2, includeDeleted: true), isNull);
    expect(seedBooks.length, 20);
    expect(InMemoryBookRepository().getAll().length, 20);
  });

  test('deleteMany может удалить весь список', () {
    expect(
      repository.deleteMany(seedBooks.map((book) => book.id).toList()),
      seedBooks.length,
    );
    expect(repository.getAll(includeDeleted: true), isEmpty);
  });
}
