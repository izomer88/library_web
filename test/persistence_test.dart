import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/author.dart';
import 'package:library_web/repositories/seed_data.dart';
import 'package:library_web/repositories/preferences_book_repository.dart';
import 'package:library_web/repositories/preferences_author_repository.dart';
import 'package:library_web/state/book_list_notifier.dart';
import 'package:library_web/state/author_list_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Book', () {
    test('JSON сохраняет все поля и дату удаления', () {
      final original = seedBooks.first.copyWith(
        deletedAt: DateTime.utc(2026, 9, 10),
      );
      final restored = Book.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(restored.toJson(), original.toJson());
      expect(Book.fromJson(seedBooks.first.toJson()).deletedAt, isNull);
    });

    test('Отсутствующие поля, null и некорректная дата безопасны', () {
      final empty = Book.fromJson({});
      expect(empty.id, 0);
      expect(empty.deletedAt, isNull);
      final nulls = {
        for (final key in seedBooks.first.toJson().keys) key: null,
      };
      expect(Book.fromJson(nulls).toJson(), empty.toJson());
      expect(Book.fromJson({'deletedAt': 'bad date'}).deletedAt, isNull);
      expect(empty.authorIds, isEmpty);
      expect(
        Book.fromJson({
          'authorIds': [1, null, 'bad', 2],
        }).authorIds,
        [1, 2],
      );
    });

    test('Первый запуск сохраняет seed и повторный запуск читает их', () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = await PreferencesBookRepository.open(prefs);
      expect(repository.getAll().length, seedBooks.length);
      expect(prefs.getString(PreferencesBookRepository.storageKey), isNotNull);
      final restored = await PreferencesBookRepository.open(prefs);
      expect(
        restored.getAll().map((item) => item.toJson()).toList(),
        seedBooks.map((item) => item.toJson()).toList(),
      );
    });

    test(
      'Удаление и восстановление переживают новое хранилище и notifier',
      () async {
        var prefs = await SharedPreferences.getInstance();
        final repository = await PreferencesBookRepository.open(prefs);
        final notifier = BookListNotifier(repository);
        addTearDown(notifier.dispose);
        await notifier.softDelete(1);
        await notifier.hardDelete(2);
        final saved = prefs.getString(PreferencesBookRepository.storageKey)!;
        SharedPreferences.setMockInitialValues({
          PreferencesBookRepository.storageKey: saved,
        });
        prefs = await SharedPreferences.getInstance();
        final restoredRepository = await PreferencesBookRepository.open(prefs);
        final restoredNotifier = BookListNotifier(restoredRepository);
        addTearDown(restoredNotifier.dispose);
        await restoredNotifier.load();
        expect(
          restoredNotifier.books.any((item) => item.id == 1 || item.id == 2),
          isFalse,
        );
        await restoredNotifier.setIncludeDeleted(true);
        expect(
          restoredNotifier.books.firstWhere((item) => item.id == 1).isDeleted,
          isTrue,
        );
        await restoredNotifier.restore(1);
        final next = await PreferencesBookRepository.open(prefs);
        expect(next.getById(1)!.deletedAt, isNull);
        expect(next.getById(2, includeDeleted: true), isNull);
        await next.restore(2);
        expect(next.getById(2, includeDeleted: true), isNull);
      },
    );

    test('Пустой список не заменяется seed', () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = await PreferencesBookRepository.open(prefs);
      for (final item in repository.getAll()) {
        await repository.hardDelete(item.id);
      }
      final restored = await PreferencesBookRepository.open(prefs);
      expect(restored.getAll(includeDeleted: true), isEmpty);
    });

    for (final broken in [
      '{broken',
      '{}',
      '[null]',
      '[{}]',
      '[{"id":1},{"id":1}]',
    ]) {
      test('Повреждённые данные заменяются seed: $broken', () async {
        SharedPreferences.setMockInitialValues({
          PreferencesBookRepository.storageKey: broken,
        });
        final prefs = await SharedPreferences.getInstance();
        final repository = await PreferencesBookRepository.open(prefs);
        expect(repository.getAll().length, seedBooks.length);
        expect(
          jsonDecode(prefs.getString(PreferencesBookRepository.storageKey)!),
          isA<List>(),
        );
      });
    }

    test('Неправильный тип значения в preferences безопасен', () async {
      SharedPreferences.setMockInitialValues({
        PreferencesBookRepository.storageKey: 42,
      });
      final repository = await PreferencesBookRepository.open(
        await SharedPreferences.getInstance(),
      );
      expect(repository.getAll().length, seedBooks.length);
    });
  });

  group('Author', () {
    test('JSON сохраняет все поля и дату удаления', () {
      final original = seedAuthors.first.copyWith(
        deletedAt: DateTime.utc(2026, 9, 10),
      );
      final restored = Author.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(restored.toJson(), original.toJson());
      expect(Author.fromJson(seedAuthors.first.toJson()).deletedAt, isNull);
    });

    test('Отсутствующие поля, null и некорректная дата безопасны', () {
      final empty = Author.fromJson({});
      expect(empty.id, 0);
      expect(empty.deletedAt, isNull);
      final nulls = {
        for (final key in seedAuthors.first.toJson().keys) key: null,
      };
      expect(Author.fromJson(nulls).toJson(), empty.toJson());
      expect(Author.fromJson({'deletedAt': 'bad date'}).deletedAt, isNull);
      expect(empty.firstName, '');
    });

    test('Первый запуск сохраняет seed и повторный запуск читает их', () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = await PreferencesAuthorRepository.open(prefs);
      expect(repository.getAll().length, seedAuthors.length);
      expect(
        prefs.getString(PreferencesAuthorRepository.storageKey),
        isNotNull,
      );
      final restored = await PreferencesAuthorRepository.open(prefs);
      expect(
        restored.getAll().map((item) => item.toJson()).toList(),
        seedAuthors.map((item) => item.toJson()).toList(),
      );
    });

    test(
      'Удаление и восстановление переживают новое хранилище и notifier',
      () async {
        var prefs = await SharedPreferences.getInstance();
        final repository = await PreferencesAuthorRepository.open(prefs);
        final notifier = AuthorListNotifier(repository);
        addTearDown(notifier.dispose);
        await notifier.softDelete(1);
        await notifier.hardDelete(2);
        final saved = prefs.getString(PreferencesAuthorRepository.storageKey)!;
        SharedPreferences.setMockInitialValues({
          PreferencesAuthorRepository.storageKey: saved,
        });
        prefs = await SharedPreferences.getInstance();
        final restoredRepository = await PreferencesAuthorRepository.open(
          prefs,
        );
        final restoredNotifier = AuthorListNotifier(restoredRepository);
        addTearDown(restoredNotifier.dispose);
        await restoredNotifier.load();
        expect(
          restoredNotifier.authors.any((item) => item.id == 1 || item.id == 2),
          isFalse,
        );
        await restoredNotifier.setIncludeDeleted(true);
        expect(
          restoredNotifier.authors.firstWhere((item) => item.id == 1).isDeleted,
          isTrue,
        );
        await restoredNotifier.restore(1);
        final next = await PreferencesAuthorRepository.open(prefs);
        expect(next.getById(1)!.deletedAt, isNull);
        expect(next.getById(2, includeDeleted: true), isNull);
        await next.restore(2);
        expect(next.getById(2, includeDeleted: true), isNull);
      },
    );

    test('Пустой список не заменяется seed', () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = await PreferencesAuthorRepository.open(prefs);
      for (final item in repository.getAll()) {
        await repository.hardDelete(item.id);
      }
      final restored = await PreferencesAuthorRepository.open(prefs);
      expect(restored.getAll(includeDeleted: true), isEmpty);
    });

    for (final broken in [
      '{broken',
      '{}',
      '[null]',
      '[{}]',
      '[{"id":1},{"id":1}]',
    ]) {
      test('Повреждённые данные заменяются seed: $broken', () async {
        SharedPreferences.setMockInitialValues({
          PreferencesAuthorRepository.storageKey: broken,
        });
        final prefs = await SharedPreferences.getInstance();
        final repository = await PreferencesAuthorRepository.open(prefs);
        expect(repository.getAll().length, seedAuthors.length);
        expect(
          jsonDecode(prefs.getString(PreferencesAuthorRepository.storageKey)!),
          isA<List>(),
        );
      });
    }

    test('Неправильный тип значения в preferences безопасен', () async {
      SharedPreferences.setMockInitialValues({
        PreferencesAuthorRepository.storageKey: 42,
      });
      final repository = await PreferencesAuthorRepository.open(
        await SharedPreferences.getInstance(),
      );
      expect(repository.getAll().length, seedAuthors.length);
    });
  });

  test('Массовое удаление сохраняется и не затрагивает авторов', () async {
    final prefs = await SharedPreferences.getInstance();
    final books = await PreferencesBookRepository.open(prefs);
    await PreferencesAuthorRepository.open(prefs);
    expect(await books.deleteMany([1, 2, 2, -1]), 2);
    final restored = await PreferencesBookRepository.open(prefs);
    expect(restored.getAll(includeDeleted: true).length, 18);
    expect(restored.getById(1, includeDeleted: true), isNull);
    expect((await PreferencesAuthorRepository.open(prefs)).getAll().length, 8);
  });

  test('После восстановления хранилища работают совместные фильтры', () async {
    final prefs = await SharedPreferences.getInstance();
    final books = await PreferencesBookRepository.open(prefs);
    await books.softDelete(6);
    final restored = await PreferencesBookRepository.open(prefs);
    expect(
      restored.getAll(
        query: 'ГОРОД',
        genreId: 4,
        publisherId: 4,
        yearFrom: 2023,
        yearTo: 2023,
      ),
      isEmpty,
    );
    expect(
      restored
          .getAll(
            query: 'ГОРОД',
            genreId: 4,
            publisherId: 4,
            yearFrom: 2023,
            yearTo: 2023,
            includeDeleted: true,
          )
          .single
          .id,
      6,
    );
  });
}
