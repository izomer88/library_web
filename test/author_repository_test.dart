import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/repositories/author_repository.dart';
import 'package:library_web/repositories/in_memory_author_repository.dart';
import 'package:library_web/repositories/seed_data.dart';

void main() {
  late AuthorRepository repository;

  setUp(() {
    repository = InMemoryAuthorRepository();
  });

  test('Список и получение по ID', () {
    expect(repository.getAll().length, seedAuthors.length);
    expect(repository.getById(1)?.id, 1);
    expect(repository.getById(-1), isNull);
    expect(repository.getAll(query: 'несуществующий текст'), isEmpty);
    expect(repository.getAll(query: '   ').length, seedAuthors.length);
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
    expect(repository.getAll(includeDeleted: true).length, seedAuthors.length);
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
    expect(repository.getAll().length, seedAuthors.length);
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
      seedAuthors.length - 2,
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
    expect(repository.getAll().length, seedAuthors.length);
    repository.hardDelete(1);
    repository.hardDelete(1);
    expect(repository.getAll().length, seedAuthors.length - 1);
  });

  test('Изменения изолированы от seed и других экземпляров', () {
    repository.softDelete(1);
    repository.hardDelete(2);
    repository.getAll().clear();
    final other = InMemoryAuthorRepository();
    expect(seedAuthors.first.isDeleted, isFalse);
    expect(seedAuthors.any((item) => item.id == 2), isTrue);
    expect(other.getAll().length, seedAuthors.length);
    expect(repository.getAll().length, seedAuthors.length - 2);
  });

  test('Поиск автора по части фамилии без учёта регистра', () {
    expect(repository.getAll(query: '  сОКОЛ  ').map((author) => author.id), [
      1,
    ]);
  });

  test('Поиск автора по стране без учёта регистра', () {
    expect(repository.getAll(query: 'рОССИЯ').map((author) => author.id), [
      1,
      2,
    ]);
    expect(repository.getAll(query: 'брит').map((author) => author.id), [3]);
  });

  test('Поиск учитывает параметр показа удалённых авторов', () {
    repository.softDelete(1);
    expect(repository.getAll(query: 'Россия').map((author) => author.id), [2]);
    expect(
      repository
          .getAll(query: 'Россия', includeDeleted: true)
          .map((author) => author.id),
      [1, 2],
    );
  });
}
