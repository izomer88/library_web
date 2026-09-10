import 'dart:async';

import '../models/book.dart';

abstract class BookRepository {
  // ID новой записи назначается репозиторием.
  FutureOr<Book> create(Book item);
  FutureOr<void> update(Book item);

  // Поиск по части текста. Все фильтры применяются одновременно.
  List<Book> getAll({
    String query = '',
    int? genreId,
    int? publisherId,
    int? yearFrom,
    int? yearTo,
    bool includeDeleted = false,
  });

  // Возвращает null, если запись отсутствует или скрыта.
  Book? getById(int id, {bool includeDeleted = false});

  // Неизвестный ID не изменяет данные.
  FutureOr<void> softDelete(int id);
  FutureOr<void> hardDelete(int id);
  FutureOr<void> restore(int id);

  // Физически удаляет записи и возвращает их фактическое количество.
  FutureOr<int> deleteMany(List<int> ids);
}
