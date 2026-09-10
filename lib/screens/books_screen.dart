import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../repositories/seed_data.dart';
import '../state/book_list_notifier.dart';
import '../state/author_list_notifier.dart';
import '../state/load_status.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  late final TextEditingController _search;
  late final TextEditingController _yearFrom;
  late final TextEditingController _yearTo;
  int? _genreId;
  int? _publisherId;
  String? _yearError;

  @override
  void initState() {
    super.initState();
    final notifier = context.read<BookListNotifier>();
    _search = TextEditingController(text: notifier.search);
    _yearFrom = TextEditingController(
      text: notifier.yearFrom?.toString() ?? '',
    );
    _yearTo = TextEditingController(text: notifier.yearTo?.toString() ?? '');
    _genreId = notifier.genreId;
    _publisherId = notifier.publisherId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (notifier.status == LoadStatus.idle) notifier.load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _yearFrom.dispose();
    _yearTo.dispose();
    super.dispose();
  }

  void _applyFilters(BookListNotifier notifier) {
    final fromText = _yearFrom.text.trim();
    final toText = _yearTo.text.trim();
    final from = int.tryParse(fromText);
    final to = int.tryParse(toText);
    if ((fromText.isNotEmpty && (from == null || from < 0)) ||
        (toText.isNotEmpty && (to == null || to < 0)) ||
        (from != null && to != null && from > to)) {
      setState(
        () => _yearError = 'Укажите корректные годы: «от» не больше «до».',
      );
      return;
    }
    setState(() => _yearError = null);
    notifier.applyFilters(
      genreId: _genreId,
      publisherId: _publisherId,
      yearFrom: from,
      yearTo: to,
    );
  }

  Future<void> _deleteSelected(BookListNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить выбранные книги?'),
        content: Text(
          'Будет окончательно удалено книг: ${notifier.selectedIds.length}. Отменить удаление нельзя.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await notifier.deleteSelected();
  }

  Future<void> _delete(Book item, BookListNotifier notifier) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удаление книги'),
        content: const Text(
          'Логическое удаление можно отменить восстановлением. Физическое удаление необратимо.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'soft'),
            child: const Text('Логически'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'hard'),
            child: const Text('Физически'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'soft') await notifier.softDelete(item.id);
    if (action == 'hard') await notifier.hardDelete(item.id);
  }

  Widget _actions(Book item, BookListNotifier notifier) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: ValueKey('edit-${item.id}'),
          tooltip: 'Редактировать',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.go('/books/${item.id}/edit'),
        ),
        IconButton(
          key: ValueKey('action-${item.id}'),
          tooltip: item.isDeleted ? 'Восстановить' : 'Удалить',
          icon: Icon(item.isDeleted ? Icons.restore : Icons.delete_outline),
          onPressed: () => item.isDeleted
              ? notifier.restore(item.id)
              : _delete(item, notifier),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    final authors = context.watch<AuthorListNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Книги'),
        actions: [
          TextButton(
            onPressed: () => context.go('/books/new'),
            child: const Text('Добавить книгу'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final items = notifier.books;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                key: const ValueKey('search'),
                controller: _search,
                decoration: const InputDecoration(
                  labelText: 'Поиск по названию и ISBN',
                ),
                onChanged: notifier.setSearch,
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('genre-$_genreId'),
                      initialValue: _genreId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Жанр'),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Все жанры'),
                        ),
                        ...seedGenres.entries.map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => _genreId = value),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('publisher-$_publisherId'),
                      initialValue: _publisherId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Издательство',
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Все издательства'),
                        ),
                        ...seedPublishers.entries.map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _publisherId = value),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      key: const ValueKey('yearFrom'),
                      controller: _yearFrom,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Год от'),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      key: const ValueKey('yearTo'),
                      controller: _yearTo,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Год до'),
                    ),
                  ),
                ],
              ),
              if (_yearError != null)
                Text(
                  _yearError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton(
                    onPressed: () => _applyFilters(notifier),
                    child: const Text('Применить'),
                  ),
                  TextButton(
                    onPressed: () {
                      _search.clear();
                      _yearFrom.clear();
                      _yearTo.clear();
                      setState(() {
                        _genreId = null;
                        _publisherId = null;
                        _yearError = null;
                      });
                      notifier.setSearch('');
                      notifier.clearFilters();
                    },
                    child: const Text('Сбросить'),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Показывать удалённые'),
                value: notifier.includeDeleted,
                onChanged: notifier.setIncludeDeleted,
              ),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Выбрано: ${notifier.selectedIds.length}'),
                  TextButton(
                    onPressed: notifier.selectedIds.isEmpty
                        ? null
                        : () => _deleteSelected(notifier),
                    child: const Text('Удалить выбранные'),
                  ),
                ],
              ),
              if (notifier.status == LoadStatus.idle ||
                  notifier.status == LoadStatus.loading)
                const Center(child: CircularProgressIndicator())
              else if (notifier.status == LoadStatus.error)
                Text(notifier.errorMessage ?? 'Не удалось загрузить данные.')
              else if (items.isEmpty)
                const Center(child: Text('Ничего не найдено'))
              else if (constraints.maxWidth < 600)
                ...items.map(
                  (item) => Card(
                    child: InkWell(
                      onTap: () => context.go('/books/${item.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Название: ${item.title}'),
                            Text(
                              'Авторы: ${authors.namesForIds(item.authorIds)}',
                            ),
                            Text('ISBN: ${item.isbn}'),
                            Text('Год: ${item.year.toString()}'),
                            Text('Страницы: ${item.pages.toString()}'),
                            if (item.isDeleted)
                              const Text(
                                'Удалено',
                                style: TextStyle(color: Colors.red),
                              ),
                            Row(
                              children: [
                                Checkbox(
                                  key: ValueKey('select-${item.id}'),
                                  value: notifier.selectedIds.contains(item.id),
                                  onChanged: item.isDeleted
                                      ? null
                                      : (_) =>
                                            notifier.toggleSelection(item.id),
                                ),
                                _actions(item, notifier),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Выбор')),

                      DataColumn(label: Text('Название')),
                      DataColumn(label: Text('Авторы')),
                      DataColumn(label: Text('ISBN')),
                      DataColumn(label: Text('Год')),
                      DataColumn(label: Text('Страницы')),
                      DataColumn(label: Text('Состояние')),
                      DataColumn(label: Text('Действия')),
                    ],
                    rows: items
                        .map(
                          (item) => DataRow(
                            onSelectChanged: (_) =>
                                context.go('/books/${item.id}'),
                            cells: [
                              DataCell(
                                Checkbox(
                                  key: ValueKey('select-${item.id}'),
                                  value: notifier.selectedIds.contains(item.id),
                                  onChanged: item.isDeleted
                                      ? null
                                      : (_) =>
                                            notifier.toggleSelection(item.id),
                                ),
                              ),
                              DataCell(Text(item.title)),
                              DataCell(
                                Text(authors.namesForIds(item.authorIds)),
                              ),
                              DataCell(Text(item.isbn)),
                              DataCell(Text(item.year.toString())),
                              DataCell(Text(item.pages.toString())),
                              DataCell(
                                Text(
                                  item.isDeleted ? 'Удалено' : 'Активно',
                                  style: item.isDeleted
                                      ? const TextStyle(color: Colors.red)
                                      : null,
                                ),
                              ),
                              DataCell(_actions(item, notifier)),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
