import '../models/author.dart';
import 'author_repository.dart';
import 'seed_data.dart';

class InMemoryAuthorRepository implements AuthorRepository {
  InMemoryAuthorRepository({List<Author>? initialData})
    : _authors = List.of(initialData ?? seedAuthors);

  final List<Author> _authors;

  @override
  Author create(Author item) {
    final nextId =
        _authors.fold<int>(
          0,
          (maxId, item) => item.id > maxId ? item.id : maxId,
        ) +
        1;
    final created = item.copyWith(id: nextId, clearDeletedAt: true);
    _authors.add(created);
    return created;
  }

  @override
  void update(Author item) {
    final index = _authors.indexWhere((current) => current.id == item.id);
    if (index == -1) throw StateError('Запись не найдена');
    _authors[index] = item;
  }

  @override
  List<Author> getAll({String query = '', bool includeDeleted = false}) {
    final search = query.trim().toLowerCase();

    return _authors.where((author) {
      if (!includeDeleted && author.isDeleted) return false;
      if (search.isNotEmpty &&
          !author.lastName.toLowerCase().contains(search) &&
          !author.country.toLowerCase().contains(search)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Author? getById(int id, {bool includeDeleted = false}) {
    for (final author in _authors) {
      if (author.id == id && (includeDeleted || !author.isDeleted)) {
        return author;
      }
    }
    return null;
  }

  @override
  void softDelete(int id) {
    final index = _authors.indexWhere((author) => author.id == id);
    if (index == -1) return;
    _authors[index] = _authors[index].copyWith(deletedAt: DateTime.now());
  }

  @override
  void hardDelete(int id) {
    _authors.removeWhere((author) => author.id == id);
  }

  @override
  void restore(int id) {
    final index = _authors.indexWhere((author) => author.id == id);
    if (index == -1) return;
    _authors[index] = _authors[index].copyWith(clearDeletedAt: true);
  }
}
