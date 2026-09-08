import '../models/author.dart';

abstract class AuthorRepository {
  // Поиск по части текста. Все фильтры применяются одновременно.
  List<Author> getAll({String query = '', bool includeDeleted = false});

  // Возвращает null, если запись отсутствует или скрыта.
  Author? getById(int id, {bool includeDeleted = false});

  // Неизвестный ID не изменяет данные.
  void softDelete(int id);
  void hardDelete(int id);
  void restore(int id);
}
