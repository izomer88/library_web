import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../state/book_list_notifier.dart';
import '../validation/validators.dart';

class BookFormScreen extends StatefulWidget {
  const BookFormScreen({super.key, this.id});
  final String? id;
  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'title': TextEditingController(),
    'isbn': TextEditingController(),
    'year': TextEditingController(),
    'pages': TextEditingController(),
    'publisherId': TextEditingController(),
    'authorIds': TextEditingController(),
    'genreIds': TextEditingController(),
    'copiesTotal': TextEditingController(),
    'copiesAvailable': TextEditingController(),
  };
  Book? _original;
  bool _loading = false;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final id = int.tryParse(widget.id!);
      final item = id == null
          ? null
          : await context.read<BookListNotifier>().getById(id);
      if (!mounted) return;
      if (item == null) {
        setState(() {
          _loading = false;
          _loadError = 'Запись не найдена';
        });
        return;
      }
      _original = item;
      _controllers['title']!.text = item.title;
      _controllers['isbn']!.text = item.isbn;
      _controllers['year']!.text = item.year.toString();
      _controllers['pages']!.text = item.pages.toString();
      _controllers['publisherId']!.text = item.publisherId.toString();
      _controllers['authorIds']!.text = item.authorIds.join(', ');
      _controllers['genreIds']!.text = item.genreIds.join(', ');
      _controllers['copiesTotal']!.text = item.copiesTotal.toString();
      _controllers['copiesAvailable']!.text = item.copiesAvailable.toString();
      setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Не удалось загрузить запись';
        });
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final notifier = context.read<BookListNotifier>();
    final item = Book(
      id: _original?.id ?? 0,
      deletedAt: _original?.deletedAt,
      title: _controllers['title']!.text.trim(),
      isbn: _controllers['isbn']!.text.trim(),
      year: int.parse(_controllers['year']!.text.trim()),
      pages: int.parse(_controllers['pages']!.text.trim()),
      publisherId: int.parse(_controllers['publisherId']!.text.trim()),
      authorIds: parseIds(_controllers['authorIds']!.text),
      genreIds: parseIds(_controllers['genreIds']!.text),
      copiesTotal: int.parse(_controllers['copiesTotal']!.text.trim()),
      copiesAvailable: int.parse(_controllers['copiesAvailable']!.text.trim()),
    );
    final success = _original == null
        ? await notifier.create(item) != null
        : await notifier.update(item);
    if (!mounted) return;
    if (success) {
      context.go('/books');
    } else {
      setState(() {
        _saving = false;
        _saveError = notifier.errorMessage ?? 'Не удалось сохранить запись';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.id == null ? 'Добавить книгу' : 'Редактировать книгу',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(child: Text(_loadError!))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const ValueKey('title'),
                      controller: _controllers['title'],
                      enabled: !_saving,
                      decoration: const InputDecoration(labelText: 'Название'),
                      keyboardType: TextInputType.text,
                      validator: (value) => validateText(value, maxLength: 200),
                    ),
                    TextFormField(
                      key: const ValueKey('isbn'),
                      controller: _controllers['isbn'],
                      enabled: !_saving,
                      decoration: const InputDecoration(labelText: 'ISBN'),
                      keyboardType: TextInputType.text,
                      validator: (value) => validateText(value, maxLength: 32),
                    ),
                    TextFormField(
                      key: const ValueKey('year'),
                      controller: _controllers['year'],
                      enabled: !_saving,
                      decoration: const InputDecoration(labelText: 'Год'),
                      keyboardType: TextInputType.number,
                      validator: (value) => validateInteger(
                        value,
                        min: 1,
                        max: DateTime.now().year,
                      ),
                    ),
                    TextFormField(
                      key: const ValueKey('pages'),
                      controller: _controllers['pages'],
                      enabled: !_saving,
                      decoration: const InputDecoration(labelText: 'Страницы'),
                      keyboardType: TextInputType.number,
                      validator: (value) => validatePositiveInteger(value),
                    ),
                    TextFormField(
                      key: const ValueKey('publisherId'),
                      controller: _controllers['publisherId'],
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'ID издательства',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => validatePositiveInteger(value),
                    ),
                    TextFormField(
                      key: const ValueKey('authorIds'),
                      controller: _controllers['authorIds'],
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'ID авторов (через запятую)',
                      ),
                      keyboardType: TextInputType.text,
                      validator: (value) => validateIds(value),
                    ),
                    TextFormField(
                      key: const ValueKey('genreIds'),
                      controller: _controllers['genreIds'],
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'ID жанров (через запятую)',
                      ),
                      keyboardType: TextInputType.text,
                      validator: (value) => validateIds(value),
                    ),
                    TextFormField(
                      key: const ValueKey('copiesTotal'),
                      controller: _controllers['copiesTotal'],
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Всего экземпляров',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => validateInteger(value, min: 0),
                    ),
                    TextFormField(
                      key: const ValueKey('copiesAvailable'),
                      controller: _controllers['copiesAvailable'],
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Доступно экземпляров',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => validateInteger(
                        value,
                        min: 0,
                        max: int.tryParse(
                          _controllers['copiesTotal']!.text.trim(),
                        ),
                      ),
                    ),
                    if (_saveError != null)
                      Text(
                        _saveError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Сохранение…' : 'Сохранить'),
                    ),
                    TextButton(
                      onPressed: _saving ? null : () => context.go('/books'),
                      child: const Text('Отмена'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
