import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';
import 'book_repository.dart';
import 'in_memory_book_repository.dart';
import 'seed_data.dart';

class PreferencesBookRepository implements BookRepository {
  PreferencesBookRepository._(this._preferences, List<Book> data)
    : _memory = InMemoryBookRepository(initialData: data);

  static const storageKey = 'library_books_v1';
  final SharedPreferences _preferences;
  final InMemoryBookRepository _memory;

  @override
  Future<Book> create(Book item) async {
    final created = _memory.create(item);
    await _save();
    return created;
  }

  @override
  Future<void> update(Book item) async {
    _memory.update(item);
    await _save();
  }

  static Future<PreferencesBookRepository> open(
    SharedPreferences preferences,
  ) async {
    var data = List<Book>.of(seedBooks);
    try {
      final raw = preferences.getString(storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is! List) throw const FormatException('Ожидался список');
        data = decoded.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Ожидался объект');
          }
          // Отсутствующий ID нельзя использовать как идентификатор записи.
          if (item['id'] is! int || (item['id'] as int) <= 0) {
            throw const FormatException('Некорректный ID');
          }
          return Book.fromJson(item);
        }).toList();
        if (data.map((item) => item.id).toSet().length != data.length) {
          throw const FormatException('Повторяющийся ID');
        }
      }
    } catch (_) {
      data = List.of(seedBooks);
    }
    final repository = PreferencesBookRepository._(preferences, data);
    await repository._save();
    return repository;
  }

  Future<void> _save() async {
    final data = _memory
        .getAll(includeDeleted: true)
        .map((item) => item.toJson())
        .toList();
    if (!await _preferences.setString(storageKey, jsonEncode(data))) {
      throw StateError('Не удалось сохранить книги');
    }
  }

  @override
  List<Book> getAll({
    String query = '',
    int? genreId,
    int? publisherId,
    int? yearFrom,
    int? yearTo,
    bool includeDeleted = false,
  }) => _memory.getAll(
    query: query,
    genreId: genreId,
    publisherId: publisherId,
    yearFrom: yearFrom,
    yearTo: yearTo,
    includeDeleted: includeDeleted,
  );

  @override
  Book? getById(int id, {bool includeDeleted = false}) =>
      _memory.getById(id, includeDeleted: includeDeleted);

  @override
  Future<void> softDelete(int id) async {
    _memory.softDelete(id);
    await _save();
  }

  @override
  Future<void> hardDelete(int id) async {
    _memory.hardDelete(id);
    await _save();
  }

  @override
  Future<void> restore(int id) async {
    _memory.restore(id);
    await _save();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    final count = _memory.deleteMany(ids);
    await _save();
    return count;
  }
}
