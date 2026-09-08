import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/models/author.dart';
import 'package:library_web/repositories/in_memory_author_repository.dart';
import 'package:library_web/repositories/seed_data.dart';
import 'package:library_web/state/author_list_notifier.dart';
import 'package:library_web/state/load_status.dart';

class TestAuthorRepository extends InMemoryAuthorRepository {
  bool failLoad = false;
  bool failMutation = false;

  @override
  List<Author> getAll({String query = '', bool includeDeleted = false}) {
    if (failLoad) throw StateError('Ошибка чтения');
    return super.getAll(query: query, includeDeleted: includeDeleted);
  }

  @override
  void softDelete(int id) {
    if (failMutation) throw StateError('Ошибка записи');
    super.softDelete(id);
  }

  @override
  void hardDelete(int id) {
    if (failMutation) throw StateError('Ошибка записи');
    super.hardDelete(id);
  }

  @override
  void restore(int id) {
    if (failMutation) throw StateError('Ошибка записи');
    super.restore(id);
  }
}

void main() {
  late TestAuthorRepository repository;
  late AuthorListNotifier notifier;

  setUp(() {
    repository = TestAuthorRepository();
    notifier = AuthorListNotifier(repository);
  });

  tearDown(() => notifier.dispose());

  test('Начальное состояние и переход loading -> success', () async {
    expect(notifier.status, LoadStatus.idle);
    expect(notifier.authors, isEmpty);
    expect(notifier.errorMessage, isNull);
    expect(notifier.search, '');
    expect(notifier.includeDeleted, isFalse);
    expect(notifier.selectedIds, isEmpty);
    final statuses = <LoadStatus>[];
    notifier.addListener(() => statuses.add(notifier.status));
    await notifier.load();
    expect(statuses, [LoadStatus.loading, LoadStatus.success]);
    expect(
      notifier.authors.map((item) => item.id),
      seedAuthors.map((item) => item.id),
    );
  });

  test('Поиск перезагружает список и очищает выбор', () async {
    await notifier.load();
    notifier.toggleSelection(2);
    await notifier.setSearch('СОКОЛОВ');
    expect(notifier.search, 'СОКОЛОВ');
    expect(notifier.authors.map((item) => item.id), [1]);
    expect(notifier.selectedIds, isEmpty);
    await notifier.setSearch('');
    expect(notifier.authors.length, seedAuthors.length);
  });

  test('Выбор переключается, очищается и сообщает слушателям', () async {
    await notifier.load();
    var notifications = 0;
    notifier.addListener(() => notifications++);
    notifier.toggleSelection(1);
    expect(notifier.selectedIds, {1});
    notifier.toggleSelection(1);
    expect(notifier.selectedIds, isEmpty);
    notifier.toggleSelection(2);
    notifier.clearSelection();
    expect(notifier.selectedIds, isEmpty);
    expect(notifications, 4);
  });

  test('Нельзя изменить список и выбор через getters', () async {
    await notifier.load();
    notifier.toggleSelection(1);
    expect(() => notifier.selectedIds.add(2), throwsUnsupportedError);
    expect(() => notifier.authors.clear(), throwsUnsupportedError);
    expect(notifier.selectedIds, {1});
    expect(notifier.authors.length, seedAuthors.length);
  });

  test('Soft delete перезагружает список и убирает ID из выбора', () async {
    await notifier.load();
    notifier.toggleSelection(1);
    await notifier.softDelete(1);
    expect(notifier.status, LoadStatus.success);
    expect(notifier.authors.any((item) => item.id == 1), isFalse);
    expect(repository.getById(1, includeDeleted: true)!.isDeleted, isTrue);
    expect(notifier.selectedIds, isEmpty);
  });

  test('includeDeleted показывает удалённые и очищает выбор', () async {
    await notifier.load();
    await notifier.softDelete(1);
    notifier.toggleSelection(2);
    await notifier.setIncludeDeleted(true);
    expect(notifier.includeDeleted, isTrue);
    expect(notifier.selectedIds, isEmpty);
    expect(
      notifier.authors.firstWhere((item) => item.id == 1).isDeleted,
      isTrue,
    );
    await notifier.setSearch('Соколов');
    expect(notifier.authors.map((item) => item.id), [1]);
    await notifier.setIncludeDeleted(false);
    expect(notifier.authors, isEmpty);
  });

  test('Restore возвращает запись и сбрасывает дату', () async {
    await notifier.softDelete(1);
    await notifier.restore(1);
    expect(notifier.status, LoadStatus.success);
    expect(
      notifier.authors.firstWhere((item) => item.id == 1).deletedAt,
      isNull,
    );
    expect(notifier.authors.length, seedAuthors.length);
  });

  test(
    'Hard delete удаляет запись окончательно и перезагружает список',
    () async {
      await notifier.load();
      notifier.toggleSelection(1);
      await notifier.hardDelete(1);
      expect(notifier.status, LoadStatus.success);
      expect(repository.getById(1, includeDeleted: true), isNull);
      expect(notifier.authors.length, seedAuthors.length - 1);
      expect(notifier.selectedIds, isEmpty);
      await notifier.restore(1);
      expect(notifier.authors.any((item) => item.id == 1), isFalse);
    },
  );

  test('Ошибка загрузки и успешный повторный запрос', () async {
    repository.failLoad = true;
    final statuses = <LoadStatus>[];
    notifier.addListener(() => statuses.add(notifier.status));
    await notifier.load();
    expect(statuses, [LoadStatus.loading, LoadStatus.error]);
    expect(notifier.errorMessage, contains('Не удалось загрузить'));
    repository.failLoad = false;
    await notifier.load();
    expect(notifier.status, LoadStatus.success);
    expect(notifier.errorMessage, isNull);
  });

  for (final operation in ['softDelete', 'hardDelete', 'restore']) {
    test('Ошибка операции $operation сохраняется в состоянии', () async {
      await notifier.load();
      repository.failMutation = true;
      switch (operation) {
        case 'softDelete':
          await notifier.softDelete(1);
        case 'hardDelete':
          await notifier.hardDelete(1);
        case 'restore':
          await notifier.restore(1);
      }
      expect(notifier.status, LoadStatus.error);
      expect(notifier.errorMessage, contains('Не удалось'));
      expect(notifier.authors.length, seedAuthors.length);
    });
  }

  test('Ошибка перезагрузки после изменения не скрывается', () async {
    await notifier.load();
    repository.failLoad = true;
    await notifier.softDelete(1);
    expect(repository.getById(1, includeDeleted: true)!.isDeleted, isTrue);
    expect(notifier.status, LoadStatus.error);
    expect(notifier.errorMessage, contains('Не удалось загрузить'));
  });

  test('Поиск авторов по стране', () async {
    await notifier.setSearch('рОССИЯ');
    expect(notifier.authors.map((author) => author.id), [1, 2]);
  });
}
