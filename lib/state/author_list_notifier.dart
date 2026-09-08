import 'package:flutter/foundation.dart';

import '../models/author.dart';
import '../repositories/author_repository.dart';
import 'load_status.dart';

class AuthorListNotifier extends ChangeNotifier {
  AuthorListNotifier(this._repository);

  final AuthorRepository _repository;
  List<Author> _authors = [];
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;
  String _search = '';
  bool _includeDeleted = false;
  final Set<int> _selectedIds = {};

  List<Author> get authors => List.unmodifiable(_authors);
  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get search => _search;
  bool get includeDeleted => _includeDeleted;
  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);

  // Связи книги не зависят от поиска и фильтров списка авторов.
  String namesForIds(List<int> ids) {
    return ids
        .map((id) {
          try {
            final author = _repository.getById(id, includeDeleted: true);
            return author == null
                ? 'Автор не найден'
                : '${author.firstName} ${author.lastName}';
          } catch (_) {
            return 'Автор недоступен';
          }
        })
        .join(', ');
  }

  // Детали доступны независимо от поиска и фильтров списка.
  Future<Author?> getById(int id) async {
    return _repository.getById(id, includeDeleted: _includeDeleted);
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _authors = _repository.getAll(
        query: _search,
        includeDeleted: _includeDeleted,
      );
      _selectedIds.retainAll(_authors.map((item) => item.id));
      _status = LoadStatus.success;
    } catch (_) {
      _status = LoadStatus.error;
      _errorMessage = 'Не удалось загрузить авторов. Попробуйте ещё раз.';
    }
    notifyListeners();
  }

  Future<void> setSearch(String value) async {
    _search = value;
    _selectedIds.clear();
    await load();
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
      _repository.softDelete(id);
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
      _repository.hardDelete(id);
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
      _repository.restore(id);
      _selectedIds.remove(id);
      await load();
    } catch (_) {
      _status = LoadStatus.error;
      _errorMessage = 'Не удалось восстановить запись. Попробуйте ещё раз.';
      notifyListeners();
    }
  }
}
