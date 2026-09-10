import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/author.dart';
import 'author_repository.dart';
import 'in_memory_author_repository.dart';
import 'seed_data.dart';

class PreferencesAuthorRepository implements AuthorRepository {
  PreferencesAuthorRepository._(this._preferences, List<Author> data)
    : _memory = InMemoryAuthorRepository(initialData: data);

  static const storageKey = 'library_authors_v1';
  final SharedPreferences _preferences;
  final InMemoryAuthorRepository _memory;

  @override
  Future<Author> create(Author item) async {
    final created = _memory.create(item);
    await _save();
    return created;
  }

  @override
  Future<void> update(Author item) async {
    _memory.update(item);
    await _save();
  }

  static Future<PreferencesAuthorRepository> open(
    SharedPreferences preferences,
  ) async {
    var data = List<Author>.of(seedAuthors);
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
          return Author.fromJson(item);
        }).toList();
        if (data.map((item) => item.id).toSet().length != data.length) {
          throw const FormatException('Повторяющийся ID');
        }
      }
    } catch (_) {
      data = List.of(seedAuthors);
    }
    final repository = PreferencesAuthorRepository._(preferences, data);
    await repository._save();
    return repository;
  }

  Future<void> _save() async {
    final data = _memory
        .getAll(includeDeleted: true)
        .map((item) => item.toJson())
        .toList();
    if (!await _preferences.setString(storageKey, jsonEncode(data))) {
      throw StateError('Не удалось сохранить авторов');
    }
  }

  @override
  List<Author> getAll({String query = '', bool includeDeleted = false}) =>
      _memory.getAll(query: query, includeDeleted: includeDeleted);

  @override
  Author? getById(int id, {bool includeDeleted = false}) =>
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
}
