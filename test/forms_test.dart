import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:library_web/main.dart';
import 'package:library_web/router.dart';
import 'package:library_web/repositories/preferences_book_repository.dart';
import 'package:library_web/repositories/preferences_author_repository.dart';
import 'package:library_web/validation/validators.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  late PreferencesBookRepository books;
  late PreferencesAuthorRepository authors;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    books = await PreferencesBookRepository.open(preferences);
    authors = await PreferencesAuthorRepository.open(preferences);
  });

  Future<void> open(WidgetTester tester, String path) async {
    tester.view.physicalSize = const Size(700, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    router.go(path);
    await tester.pumpWidget(
      MyApp(bookRepository: books, authorRepository: authors),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, Map<String, String> values) async {
    for (final entry in values.entries) {
      final field = find.byKey(ValueKey(entry.key));
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Сохранить'));
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
  }

  testWidgets('Book: создание и сохранение всех полей', (tester) async {
    await open(tester, '/books/new');
    await fill(tester, {
      "title": "Новая книга",
      "isbn": "9780000000019",
      "year": "2020",
      "pages": "123",
      "publisherId": "1",
      "authorIds": "1, 2",
      "genreIds": "2, 4",
      "copiesTotal": "3",
      "copiesAvailable": "2",
    });
    await save(tester);
    expect(router.routeInformationProvider.value.uri.path, '/books');
    final restored = await PreferencesBookRepository.open(preferences);
    final item = restored.getById(21)!;
    expect(item.title, 'Новая книга');
    expect(item.isbn, '9780000000019');
    expect(item.year, 2020);
    expect(item.pages, 123);
    expect(item.publisherId, 1);
    expect(item.authorIds, [1, 2]);
    expect(item.genreIds, [2, 4]);
    expect(item.copiesTotal, 3);
    expect(item.copiesAvailable, 2);
  });

  testWidgets('Book: редактирование заполняет поля и сохраняется', (
    tester,
  ) async {
    final before = books.getById(1)!;
    await open(tester, '/books/1/edit');
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('title')))
          .controller!
          .text,
      before.title,
    );
    await fill(tester, {'title': 'Изменённая книга'});
    await save(tester);
    final restored = await PreferencesBookRepository.open(preferences);
    final item = restored.getById(1)!;
    expect(item.title, 'Изменённая книга');
    expect(restored.getAll().length, 20);
    expect(item.toJson(), before.copyWith(title: 'Изменённая книга').toJson());
  });

  testWidgets('Book: пустые обязательные поля блокируют сохранение', (
    tester,
  ) async {
    await open(tester, '/books/new');
    await save(tester);
    expect(find.text('Обязательное поле'), findsNWidgets(9));
    expect(books.getAll().length, 20);
    expect(router.routeInformationProvider.value.uri.path, '/books/new');
  });

  testWidgets('Book: отсутствующая запись не открывает пустую форму', (
    tester,
  ) async {
    await open(tester, '/books/9999/edit');
    expect(find.text('Запись не найдена'), findsOneWidget);
    expect(find.byType(Form), findsNothing);
  });

  testWidgets('Book: кнопки списка открывают формы', (tester) async {
    await open(tester, '/books');
    await tester.tap(find.text('Добавить книгу'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/books/new');
    await tester.ensureVisible(find.text('Отмена'));
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('edit-1')));
    await tester.tap(find.byKey(const ValueKey('edit-1')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/books/1/edit');
  });

  testWidgets('Author: создание и сохранение всех полей', (tester) async {
    await open(tester, '/authors/new');
    await fill(tester, {
      "firstName": "Мария",
      "lastName": "Иванова",
      "country": "Россия",
      "birthYear": "1990",
    });
    await save(tester);
    expect(router.routeInformationProvider.value.uri.path, '/authors');
    final restored = await PreferencesAuthorRepository.open(preferences);
    final item = restored.getById(9)!;
    expect(item.firstName, 'Мария');
    expect(item.lastName, 'Иванова');
    expect(item.country, 'Россия');
    expect(item.birthYear, 1990);
  });

  testWidgets('Author: редактирование заполняет поля и сохраняется', (
    tester,
  ) async {
    final before = authors.getById(1)!;
    await open(tester, '/authors/1/edit');
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('firstName')))
          .controller!
          .text,
      before.firstName,
    );
    await fill(tester, {'firstName': 'Александра'});
    await save(tester);
    final restored = await PreferencesAuthorRepository.open(preferences);
    final item = restored.getById(1)!;
    expect(item.firstName, 'Александра');
    expect(restored.getAll().length, 8);
    expect(item.toJson(), before.copyWith(firstName: 'Александра').toJson());
  });

  testWidgets('Author: пустые обязательные поля блокируют сохранение', (
    tester,
  ) async {
    await open(tester, '/authors/new');
    await save(tester);
    expect(find.text('Обязательное поле'), findsNWidgets(4));
    expect(authors.getAll().length, 8);
    expect(router.routeInformationProvider.value.uri.path, '/authors/new');
  });

  testWidgets('Author: отсутствующая запись не открывает пустую форму', (
    tester,
  ) async {
    await open(tester, '/authors/9999/edit');
    expect(find.text('Запись не найдена'), findsOneWidget);
    expect(find.byType(Form), findsNothing);
  });

  testWidgets('Author: кнопки списка открывают формы', (tester) async {
    await open(tester, '/authors');
    await tester.tap(find.text('Добавить автора'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/authors/new');
    await tester.ensureVisible(find.text('Отмена'));
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('edit-1')));
    await tester.tap(find.byKey(const ValueKey('edit-1')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/authors/1/edit');
  });

  testWidgets('Несколько ошибок книги отображаются под своими полями', (
    tester,
  ) async {
    await open(tester, '/books/new');
    await fill(tester, {
      'title': 'Книга',
      'isbn': '123',
      'year': 'abc',
      'pages': '0',
      'publisherId': '-1',
      'authorIds': '1,,2',
      'genreIds': 'x',
      'copiesTotal': '2',
      'copiesAvailable': '3',
    });
    await save(tester);
    expect(find.text('Введите целое число'), findsOneWidget);
    expect(find.text('Значение должно быть не меньше 1'), findsNWidgets(2));
    expect(
      find.text('Введите положительные целые ID через запятую'),
      findsNWidgets(2),
    );
    expect(find.text('Значение должно быть не больше 2'), findsOneWidget);
    expect(books.getAll().length, 20);
    expect(router.routeInformationProvider.value.uri.path, '/books/new');
  });

  test('Общие валидаторы проверяют длину, целые числа, диапазоны и ID', () {
    expect(validateText('  '), isNotNull);
    expect(validateText('a', minLength: 2), isNotNull);
    expect(validateText('abcd', maxLength: 3), isNotNull);
    expect(validateText(' abc ', maxLength: 3), isNull);
    expect(validateInteger('1.5'), isNotNull);
    expect(validateInteger('-1', min: 0), isNotNull);
    expect(validateInteger('100', max: 99), isNotNull);
    expect(validatePositiveInteger('0'), isNotNull);
    expect(validatePositiveInteger('1'), isNull);
    expect(validateInteger('0', min: 0), isNull);
    expect(validateIds('1, -2'), isNotNull);
    expect(validateIds('1, 2'), isNull);
    expect(parseIds(' 1, 2 '), [1, 2]);
  });
}
