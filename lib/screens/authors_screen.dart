import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';

import '../state/author_list_notifier.dart';
import '../state/load_status.dart';

class AuthorsScreen extends StatefulWidget {
  const AuthorsScreen({super.key});

  @override
  State<AuthorsScreen> createState() => _AuthorsScreenState();
}

class _AuthorsScreenState extends State<AuthorsScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    final notifier = context.read<AuthorListNotifier>();
    _search = TextEditingController(text: notifier.search);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (notifier.status == LoadStatus.idle) notifier.load();
    });
  }

  @override
  void dispose() {
    _search.dispose();

    super.dispose();
  }

  Future<void> _delete(Author item, AuthorListNotifier notifier) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удаление автора'),
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

  Widget _actions(Author item, AuthorListNotifier notifier) {
    return IconButton(
      key: ValueKey('action-${item.id}'),
      tooltip: item.isDeleted ? 'Восстановить' : 'Удалить',
      icon: Icon(item.isDeleted ? Icons.restore : Icons.delete_outline),
      onPressed: () =>
          item.isDeleted ? notifier.restore(item.id) : _delete(item, notifier),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorListNotifier>();
    return Scaffold(
      appBar: AppBar(title: const Text('Авторы')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final items = notifier.authors;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                key: const ValueKey('search'),
                controller: _search,
                decoration: const InputDecoration(
                  labelText: 'Поиск по фамилии и стране',
                ),
                onChanged: notifier.setSearch,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Показывать удалённых'),
                value: notifier.includeDeleted,
                onChanged: notifier.setIncludeDeleted,
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
                      onTap: () => context.go('/authors/${item.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Имя: ${item.firstName}'),
                            Text('Фамилия: ${item.lastName}'),
                            Text('Страна: ${item.country}'),
                            Text('Год рождения: ${item.birthYear.toString()}'),
                            if (item.isDeleted)
                              const Text(
                                'Удалено',
                                style: TextStyle(color: Colors.red),
                              ),
                            Row(children: [_actions(item, notifier)]),
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
                      DataColumn(label: Text('Имя')),
                      DataColumn(label: Text('Фамилия')),
                      DataColumn(label: Text('Страна')),
                      DataColumn(label: Text('Год рождения')),
                      DataColumn(label: Text('Состояние')),
                      DataColumn(label: Text('Действия')),
                    ],
                    rows: items
                        .map(
                          (item) => DataRow(
                            onSelectChanged: (_) =>
                                context.go('/authors/${item.id}'),
                            cells: [
                              DataCell(Text(item.firstName)),
                              DataCell(Text(item.lastName)),
                              DataCell(Text(item.country)),
                              DataCell(Text(item.birthYear.toString())),
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
