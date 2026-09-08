import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:library_web/models/author.dart';
import 'package:library_web/repositories/in_memory_author_repository.dart';
import 'package:library_web/router.dart';
import 'package:library_web/screens/author_details_screen.dart';
import 'package:library_web/state/author_list_notifier.dart';
import 'package:library_web/state/load_status.dart';

class LoadingNotifier extends AuthorListNotifier {
  LoadingNotifier() : super(InMemoryAuthorRepository());

  @override
  LoadStatus get status => LoadStatus.loading;
}

class FailingRepository extends InMemoryAuthorRepository {
  @override
  List<Author> getAll({String query = '', bool includeDeleted = false}) =>
      throw StateError('Ошибка чтения');

  @override
  Author? getById(int id, {bool includeDeleted = false}) =>
      throw StateError('Ошибка чтения');
}

Future<void> showScreen(
  WidgetTester tester,
  AuthorListNotifier notifier, {
  String path = '/authors',
  double width = 800,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  router.go(path);
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthorListNotifier>.value(
      value: notifier,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  late AuthorListNotifier notifier;
  setUp(() {
    notifier = AuthorListNotifier(InMemoryAuthorRepository());
  });
  tearDown(() => notifier.dispose());

  for (final width in [375.0, 1200.0]) {
    testWidgets('Поиск, удаление и восстановление при $width', (tester) async {
      await showScreen(tester, notifier, width: width);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('search')), 'Соколов');
      await tester.pumpAndSettle();
      expect(notifier.authors.map((item) => item.id), [1]);
      await tester.ensureVisible(find.byKey(const ValueKey('action-1')));
      await tester.tap(find.byKey(const ValueKey('action-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Логически'));
      await tester.pumpAndSettle();
      expect(notifier.authors, isEmpty);
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(notifier.authors.single.isDeleted, isTrue);
      expect(find.text('Удалено'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('action-1')));
      await tester.tap(find.byKey(const ValueKey('action-1')));
      await tester.pumpAndSettle();
      expect(notifier.authors.single.isDeleted, isFalse);
      await tester.ensureVisible(find.byKey(const ValueKey('action-1')));
      await tester.tap(find.byKey(const ValueKey('action-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Физически'));
      await tester.pumpAndSettle();
      expect(notifier.authors, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Поиск по стране через поле ввода', (tester) async {
    await showScreen(tester, notifier);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('search')), 'рОССИЯ');
    await tester.pumpAndSettle();
    expect(notifier.authors.map((author) => author.id), [1, 2]);
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
    expect(find.text('Иван'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Пустой результат', (tester) async {
    await notifier.setSearch('несуществующий текст');
    await showScreen(tester, notifier);
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
  });

  testWidgets('Ошибка загрузки списка', (tester) async {
    final failed = AuthorListNotifier(FailingRepository());
    addTearDown(failed.dispose);
    await showScreen(tester, failed);
    await tester.pumpAndSettle();
    expect(
      find.text('Не удалось загрузить авторов. Попробуйте ещё раз.'),
      findsOneWidget,
    );
  });

  testWidgets('При 599 px карточки, при 600 px таблица', (tester) async {
    await showScreen(tester, notifier, width: 599);
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Имя: Иван'), findsOneWidget);
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
      await tester.tap(find.text(width < 600 ? 'Имя: Иван' : 'Иван'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/authors/1');
      expect(find.byType(AuthorDetailsScreen), findsOneWidget);
      expect(find.text('Имя: Иван'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Прямой URL деталей работает до загрузки списка', (tester) async {
    await showScreen(tester, notifier, path: '/authors/1');
    await tester.pumpAndSettle();
    expect(find.text('Имя: Иван'), findsOneWidget);
    expect(notifier.status, LoadStatus.idle);
  });

  testWidgets('Детали не зависят от поискового результата', (tester) async {
    await notifier.setSearch('несуществующий текст');
    await showScreen(tester, notifier, path: '/authors/1');
    await tester.pumpAndSettle();
    expect(find.text('Имя: Иван'), findsOneWidget);
    expect(notifier.authors, isEmpty);
  });

  for (final id in ['9999', 'invalid']) {
    testWidgets('Отсутствующий или некорректный ID: $id', (tester) async {
      await showScreen(tester, notifier, path: '/authors/$id');
      await tester.pumpAndSettle();
      expect(find.text('Автор не найден'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Ошибка получения деталей', (tester) async {
    final failed = AuthorListNotifier(FailingRepository());
    addTearDown(failed.dispose);
    await showScreen(tester, failed, path: '/authors/1');
    await tester.pumpAndSettle();
    expect(find.text('Не удалось загрузить автора.'), findsOneWidget);
  });

  testWidgets('Детали обновляются при смене ID в URL', (tester) async {
    await showScreen(tester, notifier, path: '/authors/1');
    await tester.pumpAndSettle();
    router.go('/authors/2');
    await tester.pumpAndSettle();
    expect(find.text('Имя: Анна'), findsOneWidget);
    expect(find.text('Имя: Иван'), findsNothing);
  });
}
