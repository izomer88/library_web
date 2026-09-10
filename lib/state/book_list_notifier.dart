import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../repositories/book_repository.dart';
import 'load_status.dart';

class BookListNotifier extends ChangeNotifier {
  BookListNotifier(this._repository);

  final BookRepository _repository;
  List<Book> _books = [];
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;
  String _search = '';
  int? _genreId;
  int? _publisherId;
  int? _yearFrom;
  int? _yearTo;
  bool _includeDeleted = false;
  final Set<int> _selectedIds = {};

  List<Book> get books => List.unmodifiable(_books);
  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get search => _search;
  int? get genreId => _genreId;
  int? get publisherId => _publisherId;
  int? get yearFrom => _yearFrom;
  int? get yearTo => _yearTo;
  bool get includeDeleted => _includeDeleted;
  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);

  Future<Book?> create(Book item) async {
    try {
      final created = await _repository.create(item);
      await load();
      return created;
    } catch (_) {
      _status = LoadStatus.error;
      _errorMessage = 'Не удалось создать запись. Попробуйте ещё раз.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> update(Book item) async {
    try {
      await _repository.update(item);
      await load();
      return true;
    } catch (_) {
      _status = LoadStatus.error;
      _errorMessage = 'Не удалось сохранить изменения. Попробуйте ещё раз.';
      notifyListeners();
      return false;
    }
  }

  // Детали доступны независимо от поиска и фильтров списка.
  Future<Book?> getById(int id) async {
    return _repository.getById(id, includeDeleted: _includeDeleted);
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _books = _repository.getAll(
        query: _search,
        genreId: _genreId,
        publisherId: _publisherId,
        yearFrom: _yearFrom,
        yearTo: _yearTo,
        includeDeleted: _includeDeleted,
      );
      _selectedIds.retainAll(_books.map((item) => item.id));
      _status = LoadStatus.success;
    } catch (_) {
      _status = LoadStatus.error;
      _errorMessage = 'Не удалось загрузить книги. Попробуйте ещё раз.';
    }
    notifyListeners();
  }

  Future<void> setSearch(String value) async {
    _search = value;
    _selectedIds.clear();
    await load();
  }

  // Каждый вызов задаёт весь набор фильтров; null снимает ограничение.
  Future<void> applyFilters({
    int? genreId,
    int? publisherId,
    int? yearFrom,
    int? yearTo,
  }) async {
    _genreId = genreId;
    _publisherId = publisherId;
    _yearFrom = yearFrom;
    _yearTo = yearTo;
    _selectedIds.clear();
    await load();
  }

  // Сбрасывает четыре фильтра, сохраняя поиск и includeDeleted.
  Future<void> clearFilters() async {
    await applyFilters();
  }

  Future<void> setIncludeDeleted(bool value) async {
    _includeDeleted = value;
    _selectedIds.clear();
    await load();
  }

  void toggleSelection(int id) {
    if (!_selectedIds.remove(id)) {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  Future<void> softDelete(int id) async {
    try {
      await _repository.softDelete(id);
      _selectedIds.remove(id);
      await load();
    } catch (_) {
      _status = LoadStatus.error;
      _errorMessage =
          'Не удалось логически удалить запись. Попробуйте ещё раз.';
      notifyListeners();
    }
  }

  Future<void> hardDelete(int id) async {
    try {
      await _repository.hardDelete(id);
      _selectedIds.remove(id);
      await load();
    } catch (_) {
      _status = LoadStatus.error;
      _errorMessage =
          'Не удалось удалить запись окончательно. Попробуйте ещё раз.';
      notifyListeners();
    }
  }

  Future<void> restore(int id) async {
    try {
      await _repository.restore(id);
      _selectedIds.remove(id);
      await load();
    } catch (_) {
      _status = LoadStatus.error;
      _errorMessage = 'Не удалось восстановить запись. Попробуйте ещё раз.';
      notifyListeners();
    }
  }

  Future<int> deleteSelected() async {
    try {
      final deletedCount = await _repository.deleteMany(_selectedIds.toList());
      _selectedIds.clear();
      await load();
      return deletedCount;
    } catch (_) {
      _status = LoadStatus.error;
      _errorMessage = 'Не удалось удалить выбранные книги. Попробуйте ещё раз.';
      notifyListeners();
      return 0;
    }
  }
}
