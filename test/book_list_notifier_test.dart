import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/repositories/in_memory_book_repository.dart';
import 'package:library_web/repositories/seed_data.dart';
import 'package:library_web/state/book_list_notifier.dart';
import 'package:library_web/state/load_status.dart';

class TestBookRepository extends InMemoryBookRepository {
  bool failLoad = false;
  bool failMutation = false;
  List<int>? receivedIds;

  @override
  List<Book> getAll({
    String query = '',
    int? genreId,
    int? publisherId,
    int? yearFrom,
    int? yearTo,
    bool includeDeleted = false,
  }) {
    if (failLoad) throw StateError('Ошибка чтения');
    return super.getAll(
      query: query,
      genreId: genreId,
      publisherId: publisherId,
      yearFrom: yearFrom,
      yearTo: yearTo,
      includeDeleted: includeDeleted,
    );
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

  @override
  int deleteMany(List<int> ids) {
    receivedIds = List.of(ids);
    if (failMutation) throw StateError('Ошибка удаления');
    return super.deleteMany(ids);
  }
}

void main() {
  late TestBookRepository repository;
  late BookListNotifier notifier;

  setUp(() {
    repository = TestBookRepository();
    notifier = BookListNotifier(repository);
  });

  tearDown(() => notifier.dispose());

  test('includeDeleted сохраняет активные книги и возвращает удалённые с фильтрами', () async {
    await notifier.setSearch('978000');
    await notifier.applyFilters(
      genreId: 1,
      publisherId: 1,
      yearFrom: 1998,
      yearTo: 2011,
    );
    expect(notifier.books.map((book) => book.id), [1, 17]);
    await notifier.softDelete(1);
    expect(notifier.books.map((book) => book.id), [17]);
    expect(repository.getById(1, includeDeleted: true)!.deletedAt, isNotNull);
    await notifier.setIncludeDeleted(true);
    expect(notifier.books.map((book) => book.id), [1, 17]);
    expect(notifier.books.first.isDeleted, isTrue);
    expect(notifier.books.last.isDeleted, isFalse);
    await notifier.restore(1);
    expect(repository.getById(1)!.deletedAt, isNull);
    await notifier.setIncludeDeleted(false);
    expect(notifier.books.map((book) => book.id), [1, 17]);
    await notifier.hardDelete(1);
    await notifier.setIncludeDeleted(true);
    await notifier.restore(1);
    expect(notifier.books.map((book) => book.id), [17]);
    expect(repository.getById(1, includeDeleted: true), isNull);
  });

  test('Начальное состояние и переход loading -> success', () async {
    expect(notifier.status, LoadStatus.idle);
    expect(notifier.books, isEmpty);
    expect(notifier.errorMessage, isNull);
    expect(notifier.search, '');
    expect(notifier.includeDeleted, isFalse);
    expect(notifier.selectedIds, isEmpty);
    final statuses = <LoadStatus>[];
    notifier.addListener(() => statuses.add(notifier.status));
    await notifier.load();
    expect(statuses, [LoadStatus.loading, LoadStatus.success]);
    expect(
      notifier.books.map((item) => item.id),
      seedBooks.map((item) => item.id),
    );
  });

  test('Поиск перезагружает список и очищает выбор', () async {
    await notifier.load();
    notifier.toggleSelection(2);
    await notifier.setSearch('ДОМ У РЕКИ');
    expect(notifier.search, 'ДОМ У РЕКИ');
    expect(notifier.books.map((item) => item.id), [1]);
    expect(notifier.selectedIds, isEmpty);
    await notifier.setSearch('');
    expect(notifier.books.length, seedBooks.length);
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
    expect(() => notifier.books.clear(), throwsUnsupportedError);
    expect(notifier.selectedIds, {1});
    expect(notifier.books.length, seedBooks.length);
  });

  test('Soft delete перезагружает список и убирает ID из выбора', () async {
    await notifier.load();
    notifier.toggleSelection(1);
    await notifier.softDelete(1);
    expect(notifier.status, LoadStatus.success);
    expect(notifier.books.any((item) => item.id == 1), isFalse);
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
    expect(notifier.books.firstWhere((item) => item.id == 1).isDeleted, isTrue);
    await notifier.setSearch('Дом у реки');
    expect(notifier.books.map((item) => item.id), [1]);
    await notifier.setIncludeDeleted(false);
    expect(notifier.books, isEmpty);
  });

  test('Restore возвращает запись и сбрасывает дату', () async {
    await notifier.softDelete(1);
    await notifier.restore(1);
    expect(notifier.status, LoadStatus.success);
    expect(notifier.books.firstWhere((item) => item.id == 1).deletedAt, isNull);
    expect(notifier.books.length, seedBooks.length);
  });

  test(
    'Hard delete удаляет запись окончательно и перезагружает список',
    () async {
      await notifier.load();
      notifier.toggleSelection(1);
      await notifier.hardDelete(1);
      expect(notifier.status, LoadStatus.success);
      expect(repository.getById(1, includeDeleted: true), isNull);
      expect(notifier.books.length, seedBooks.length - 1);
      expect(notifier.selectedIds, isEmpty);
      await notifier.restore(1);
      expect(notifier.books.any((item) => item.id == 1), isFalse);
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
      expect(notifier.books.length, seedBooks.length);
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

  test('Поиск и несколько фильтров одновременно', () async {
    await notifier.setSearch('ГОРОД');
    notifier.toggleSelection(1);
    await notifier.applyFilters(
      genreId: 4,
      publisherId: 4,
      yearFrom: 2023,
      yearTo: 2023,
    );
    expect(notifier.genreId, 4);
    expect(notifier.publisherId, 4);
    expect(notifier.yearFrom, 2023);
    expect(notifier.yearTo, 2023);
    expect(notifier.books.map((book) => book.id), [6]);
    expect(notifier.selectedIds, isEmpty);
    await notifier.applyFilters(
      genreId: 1,
      publisherId: 4,
      yearFrom: 2023,
      yearTo: 2023,
    );
    expect(notifier.books, isEmpty);
  });

  test('Одна граница годов и сброс фильтров', () async {
    await notifier.applyFilters(yearFrom: 2023);
    expect(notifier.books.map((book) => book.id), [6, 19, 20]);
    await notifier.applyFilters(yearTo: 1998);
    expect(notifier.yearFrom, isNull);
    expect(notifier.books.map((book) => book.id), [1, 7]);
    await notifier.setSearch('Дом');
    await notifier.setIncludeDeleted(true);
    notifier.toggleSelection(1);
    await notifier.clearFilters();
    expect(notifier.genreId, isNull);
    expect(notifier.publisherId, isNull);
    expect(notifier.yearFrom, isNull);
    expect(notifier.yearTo, isNull);
    expect(notifier.search, 'Дом');
    expect(notifier.includeDeleted, isTrue);
    expect(notifier.selectedIds, isEmpty);
    expect(notifier.books.map((book) => book.id), [1]);
  });

  test(
    'deleteSelected передаёт ID, возвращает количество и очищает выбор',
    () async {
      await notifier.load();
      notifier.toggleSelection(1);
      notifier.toggleSelection(2);
      notifier.toggleSelection(3);
      repository.hardDelete(3);
      expect(await notifier.deleteSelected(), 2);
      expect(repository.receivedIds, unorderedEquals([1, 2, 3]));
      expect(notifier.selectedIds, isEmpty);
      expect(notifier.books.length, seedBooks.length - 3);
      expect(
        notifier.books.any((book) => [1, 2, 3].contains(book.id)),
        isFalse,
      );
      expect(notifier.status, LoadStatus.success);
      expect(await notifier.deleteSelected(), 0);
    },
  );

  test(
    'Ошибка deleteSelected сохраняет выбор и данные для повторной попытки',
    () async {
      await notifier.load();
      notifier.toggleSelection(1);
      repository.failMutation = true;
      expect(await notifier.deleteSelected(), 0);
      expect(notifier.status, LoadStatus.error);
      expect(
        notifier.errorMessage,
        contains('Не удалось удалить выбранные книги'),
      );
      expect(notifier.selectedIds, {1});
      expect(notifier.books.length, seedBooks.length);
      repository.failMutation = false;
      expect(await notifier.deleteSelected(), 1);
      expect(notifier.errorMessage, isNull);
    },
  );
}
