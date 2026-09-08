import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/repositories/in_memory_book_repository.dart';
import 'package:library_web/router.dart';
import 'package:library_web/screens/book_details_screen.dart';
import 'package:library_web/state/book_list_notifier.dart';
import 'package:library_web/state/load_status.dart';
import 'package:library_web/state/author_list_notifier.dart';
import 'package:library_web/repositories/in_memory_author_repository.dart';

class LoadingNotifier extends BookListNotifier {
  LoadingNotifier() : super(InMemoryBookRepository());

  @override
  LoadStatus get status => LoadStatus.loading;
}

class FailingRepository extends InMemoryBookRepository {
  @override
  List<Book> getAll({
    String query = '',
    int? genreId,
    int? publisherId,
    int? yearFrom,
    int? yearTo,
    bool includeDeleted = false,
  }) => throw StateError('Ошибка чтения');

  @override
  Book? getById(int id, {bool includeDeleted = false}) =>
      throw StateError('Ошибка чтения');
}

Future<void> showScreen(
  WidgetTester tester,
  BookListNotifier notifier, {
  String path = '/books',
  double width = 800,
  AuthorListNotifier? authors,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  router.go(path);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BookListNotifier>.value(value: notifier),
        if (authors != null)
          ChangeNotifierProvider<AuthorListNotifier>.value(value: authors)
        else
          ChangeNotifierProvider(
            create: (_) => AuthorListNotifier(InMemoryAuthorRepository()),
          ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  late BookListNotifier notifier;
  setUp(() {
    notifier = BookListNotifier(InMemoryBookRepository());
  });
  tearDown(() => notifier.dispose());

  for (final width in [375.0, 1200.0]) {
    testWidgets('Авторы книги и отсутствующий автор при $width', (
      tester,
    ) async {
      final authors = AuthorListNotifier(InMemoryAuthorRepository());
      addTearDown(authors.dispose);
      await authors.setSearch('Соколов');
      await notifier.setSearch('Экспедиция к звёздам');
      await showScreen(tester, notifier, width: width, authors: authors);
      await tester.pumpAndSettle();
      final prefix = width < 600 ? 'Авторы: ' : '';
      expect(find.text('$prefixЛукас Вебер, Джеймс Миллер'), findsOneWidget);
      await authors.softDelete(5);
      await tester.pumpAndSettle();
      expect(find.text('$prefixЛукас Вебер, Джеймс Миллер'), findsOneWidget);
      await authors.hardDelete(5);
      await tester.pumpAndSettle();
      expect(
        find.text('$prefixАвтор не найден, Джеймс Миллер'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [375.0, 1200.0]) {
    testWidgets('Поиск, удаление и восстановление при $width', (tester) async {
      await notifier.applyFilters(
        genreId: 1,
        publisherId: 1,
        yearFrom: 1998,
        yearTo: 1998,
      );
      await showScreen(tester, notifier, width: width);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('search')),
        '9780000000019',
      );
      await tester.pumpAndSettle();
      expect(notifier.books.map((item) => item.id), [1]);
      await tester.ensureVisible(find.byKey(const ValueKey('action-1')));
      await tester.tap(find.byKey(const ValueKey('action-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Логически'));
      await tester.pumpAndSettle();
      expect(notifier.books, isEmpty);
      expect(notifier.includeDeleted, isFalse);
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(notifier.books.single.isDeleted, isTrue);
      expect(notifier.includeDeleted, isTrue);
      expect(find.byTooltip('Восстановить'), findsOneWidget);
      expect(find.text('Удалено'), findsOneWidget);
      expect(
        tester
            .widget<Checkbox>(find.byKey(const ValueKey('select-1')))
            .onChanged,
        isNull,
      );

      await tester.ensureVisible(find.byKey(const ValueKey('action-1')));
      await tester.tap(find.byKey(const ValueKey('action-1')));
      await tester.pumpAndSettle();
      expect(notifier.books.single.isDeleted, isFalse);
      expect(notifier.books.single.deletedAt, isNull);
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(notifier.includeDeleted, isFalse);
      expect(notifier.books.single.id, 1);
      await tester.ensureVisible(find.byKey(const ValueKey('action-1')));
      await tester.tap(find.byKey(const ValueKey('action-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Физически'));
      await tester.pumpAndSettle();
      expect(notifier.books, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [375.0, 1200.0]) {
    testWidgets('Массовое удаление: отмена и подтверждение при $width', (
      tester,
    ) async {
      await showScreen(tester, notifier, width: width);
      await tester.pumpAndSettle();
      for (final id in [1, 2]) {
        await tester.ensureVisible(find.byKey(ValueKey('select-$id')));
        await tester.tap(find.byKey(ValueKey('select-$id')));
        await tester.pumpAndSettle();
      }
      expect(notifier.selectedIds, {1, 2});
      await tester.drag(find.byType(ListView), const Offset(0, 1500));
      await tester.pumpAndSettle();
      expect(find.text('Выбрано: 2'), findsOneWidget);
      await tester.ensureVisible(find.text('Удалить выбранные'));
      await tester.tap(find.text('Удалить выбранные'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(notifier.selectedIds, {1, 2});
      expect(notifier.books.length, 20);
      await tester.tap(find.text('Удалить выбранные'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      expect(notifier.selectedIds, isEmpty);
      expect(notifier.books.length, 18);
      expect(
        notifier.books.any((book) => book.id == 1 || book.id == 2),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Поиск и все фильтры применяются вместе, сброс очищает условия', (
    tester,
  ) async {
    await showScreen(tester, notifier, width: 1200);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('search')), 'ГОРОД');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Фантастика').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Мир знаний').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('yearFrom')), '2023');
    await tester.enterText(find.byKey(const ValueKey('yearTo')), '2023');
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();
    expect(notifier.books.map((book) => book.id), [6]);
    expect(notifier.genreId, 4);
    expect(notifier.publisherId, 4);
    expect(notifier.yearFrom, 2023);
    expect(notifier.yearTo, 2023);
    await tester.tap(find.text('Сбросить'));
    await tester.pumpAndSettle();
    expect(notifier.books.length, 20);
    expect(notifier.search, '');
    expect(notifier.genreId, isNull);
    expect(notifier.publisherId, isNull);
    expect(notifier.yearFrom, isNull);
    expect(notifier.yearTo, isNull);
  });

  testWidgets('Некорректные годы не применяются', (tester) async {
    await showScreen(tester, notifier, width: 1200);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('yearFrom')), '2025');
    await tester.enterText(find.byKey(const ValueKey('yearTo')), '2000');
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();
    expect(
      find.text('Укажите корректные годы: «от» не больше «до».'),
      findsOneWidget,
    );
    expect(notifier.yearFrom, isNull);
    await tester.enterText(find.byKey(const ValueKey('yearFrom')), 'abc');
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();
    expect(notifier.yearFrom, isNull);
    expect(notifier.books.length, 20);
  });

  testWidgets('Индикатор во время loading', (tester) async {
    final loading = LoadingNotifier();
    addTearDown(loading.dispose);
    await showScreen(tester, loading);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(DataTable), findsNothing);
  });

  testWidgets('Первое открытие загружает реальные данные', (tester) async {
    expect(notifier.status, LoadStatus.idle);
    await showScreen(tester, notifier);
    await tester.pumpAndSettle();
    expect(notifier.status, LoadStatus.success);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Дом у реки'), findsOneWidget);
    expect(find.byType(Checkbox), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Пустой результат', (tester) async {
    await notifier.setSearch('несуществующий текст');
    await showScreen(tester, notifier);
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
  });

  testWidgets('Ошибка загрузки списка', (tester) async {
    final failed = BookListNotifier(FailingRepository());
    addTearDown(failed.dispose);
    await showScreen(tester, failed);
    await tester.pumpAndSettle();
    expect(
      find.text('Не удалось загрузить книги. Попробуйте ещё раз.'),
      findsOneWidget,
    );
  });

  testWidgets('При 599 px карточки, при 600 px таблица', (tester) async {
    await showScreen(tester, notifier, width: 599);
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Название: Дом у реки'), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(600, 800);
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [375.0, 800.0]) {
    testWidgets('Переход из списка в детали при ширине $width', (tester) async {
      await showScreen(tester, notifier, width: width);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(width < 600 ? 'Название: Дом у реки' : 'Дом у реки'),
      );
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/books/1');
      expect(find.byType(BookDetailsScreen), findsOneWidget);
      expect(find.text('Название: Дом у реки'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Прямой URL деталей работает до загрузки списка', (tester) async {
    await showScreen(tester, notifier, path: '/books/1');
    await tester.pumpAndSettle();
    expect(find.text('Название: Дом у реки'), findsOneWidget);
    expect(notifier.status, LoadStatus.idle);
  });

  testWidgets('Детали не зависят от поискового результата', (tester) async {
    await notifier.setSearch('несуществующий текст');
    await showScreen(tester, notifier, path: '/books/1');
    await tester.pumpAndSettle();
    expect(find.text('Название: Дом у реки'), findsOneWidget);
    expect(notifier.books, isEmpty);
  });

  for (final id in ['9999', 'invalid']) {
    testWidgets('Отсутствующий или некорректный ID: $id', (tester) async {
      await showScreen(tester, notifier, path: '/books/$id');
      await tester.pumpAndSettle();
      expect(find.text('Книга не найдена'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Ошибка получения деталей', (tester) async {
    final failed = BookListNotifier(FailingRepository());
    addTearDown(failed.dispose);
    await showScreen(tester, failed, path: '/books/1');
    await tester.pumpAndSettle();
    expect(find.text('Не удалось загрузить книгу.'), findsOneWidget);
  });

  testWidgets('Детали обновляются при смене ID в URL', (tester) async {
    await showScreen(tester, notifier, path: '/books/1');
    await tester.pumpAndSettle();
    router.go('/books/2');
    await tester.pumpAndSettle();
    expect(find.text('Название: Зимняя дорога'), findsOneWidget);
    expect(find.text('Название: Дом у реки'), findsNothing);
  });
}
