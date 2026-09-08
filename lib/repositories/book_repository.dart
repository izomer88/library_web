import '../models/book.dart';

abstract class BookRepository {
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
  void softDelete(int id);
  void hardDelete(int id);
  void restore(int id);

  // Физически удаляет записи и возвращает их фактическое количество.
  int deleteMany(List<int> ids);
}
