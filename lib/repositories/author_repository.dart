import 'dart:async';

import '../models/author.dart';

abstract class AuthorRepository {
  // ID новой записи назначается репозиторием.
  FutureOr<Author> create(Author item);
  FutureOr<void> update(Author item);

  // Поиск по части текста. Все фильтры применяются одновременно.
  List<Author> getAll({String query = '', bool includeDeleted = false});

  // Возвращает null, если запись отсутствует или скрыта.
  Author? getById(int id, {bool includeDeleted = false});

  // Неизвестный ID не изменяет данные.
  FutureOr<void> softDelete(int id);
  FutureOr<void> hardDelete(int id);
  FutureOr<void> restore(int id);
}
