import '../models/book.dart';
import 'book_repository.dart';
import 'seed_data.dart';

class InMemoryBookRepository implements BookRepository {
  InMemoryBookRepository({List<Book>? initialData})
    : _books = List.of(initialData ?? seedBooks);

  final List<Book> _books;

  @override
  Book create(Book item) {
    final nextId =
        _books.fold<int>(
          0,
          (maxId, item) => item.id > maxId ? item.id : maxId,
        ) +
        1;
    final created = item.copyWith(id: nextId, clearDeletedAt: true);
    _books.add(created);
    return created;
  }

  @override
  void update(Book item) {
    final index = _books.indexWhere((current) => current.id == item.id);
    if (index == -1) throw StateError('Запись не найдена');
    _books[index] = item;
  }

  @override
  List<Book> getAll({
    String query = '',
    int? genreId,
    int? publisherId,
    int? yearFrom,
    int? yearTo,
    bool includeDeleted = false,
  }) {
    final search = query.trim().toLowerCase();

    return _books.where((book) {
      if (!includeDeleted && book.isDeleted) return false;
      if (search.isNotEmpty &&
          !book.title.toLowerCase().contains(search) &&
          !book.isbn.toLowerCase().contains(search)) {
        return false;
      }
      if (genreId != null && !book.genreIds.contains(genreId)) return false;
      if (publisherId != null && book.publisherId != publisherId) return false;
      if (yearFrom != null && book.year < yearFrom) return false;
      if (yearTo != null && book.year > yearTo) return false;
      return true;
    }).toList();
  }

  @override
  Book? getById(int id, {bool includeDeleted = false}) {
    for (final book in _books) {
      if (book.id == id && (includeDeleted || !book.isDeleted)) {
        return book;
      }
    }
    return null;
  }

  @override
  void softDelete(int id) {
    final index = _books.indexWhere((book) => book.id == id);
    if (index == -1) return;
    _books[index] = _books[index].copyWith(deletedAt: DateTime.now());
  }

  @override
  void hardDelete(int id) {
    _books.removeWhere((book) => book.id == id);
  }

  @override
  void restore(int id) {
    final index = _books.indexWhere((book) => book.id == id);
    if (index == -1) return;
    _books[index] = _books[index].copyWith(clearDeletedAt: true);
  }

  @override
  int deleteMany(List<int> ids) {
    final idsToDelete = ids.toSet();
    final countBefore = _books.length;
    _books.removeWhere((book) => idsToDelete.contains(book.id));
    return countBefore - _books.length;
  }
}
