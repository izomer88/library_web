import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../state/author_list_notifier.dart';
import '../validation/validators.dart';

class AuthorFormScreen extends StatefulWidget {
  const AuthorFormScreen({super.key, this.id});
  final String? id;
  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'firstName': TextEditingController(),
    'lastName': TextEditingController(),
    'country': TextEditingController(),
    'birthYear': TextEditingController(),
  };
  Author? _original;
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
          : await context.read<AuthorListNotifier>().getById(id);
      if (!mounted) return;
      if (item == null) {
        setState(() {
          _loading = false;
          _loadError = 'Запись не найдена';
        });
        return;
      }
      _original = item;
      _controllers['firstName']!.text = item.firstName;
      _controllers['lastName']!.text = item.lastName;
      _controllers['country']!.text = item.country;
      _controllers['birthYear']!.text = item.birthYear.toString();
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
    final notifier = context.read<AuthorListNotifier>();
    final item = Author(
      id: _original?.id ?? 0,
      deletedAt: _original?.deletedAt,
      firstName: _controllers['firstName']!.text.trim(),
      lastName: _controllers['lastName']!.text.trim(),
      country: _controllers['country']!.text.trim(),
      birthYear: int.parse(_controllers['birthYear']!.text.trim()),
    );
    final success = _original == null
        ? await notifier.create(item) != null
        : await notifier.update(item);
    if (!mounted) return;
    if (success) {
      context.go('/authors');
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
          widget.id == null ? 'Добавить автора' : 'Редактировать автора',
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
                      key: const ValueKey('firstName'),
                      controller: _controllers['firstName'],
                      enabled: !_saving,
                      decoration: const InputDecoration(labelText: 'Имя'),
                      keyboardType: TextInputType.text,
                      validator: (value) => validateText(value, maxLength: 100),
                    ),
                    TextFormField(
                      key: const ValueKey('lastName'),
                      controller: _controllers['lastName'],
                      enabled: !_saving,
                      decoration: const InputDecoration(labelText: 'Фамилия'),
                      keyboardType: TextInputType.text,
                      validator: (value) => validateText(value, maxLength: 100),
                    ),
                    TextFormField(
                      key: const ValueKey('country'),
                      controller: _controllers['country'],
                      enabled: !_saving,
                      decoration: const InputDecoration(labelText: 'Страна'),
                      keyboardType: TextInputType.text,
                      validator: (value) => validateText(value, maxLength: 100),
                    ),
                    TextFormField(
                      key: const ValueKey('birthYear'),
                      controller: _controllers['birthYear'],
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Год рождения',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => validateInteger(
                        value,
                        min: 1,
                        max: DateTime.now().year,
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
                      onPressed: _saving ? null : () => context.go('/authors'),
                      child: const Text('Отмена'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
