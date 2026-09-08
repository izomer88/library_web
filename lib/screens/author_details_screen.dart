import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../state/author_list_notifier.dart';

class AuthorDetailsScreen extends StatefulWidget {
  const AuthorDetailsScreen({super.key, required this.id});

  final String id;

  @override
  State<AuthorDetailsScreen> createState() => _AuthorDetailsScreenState();
}

class _AuthorDetailsScreenState extends State<AuthorDetailsScreen> {
  late Future<Author?> _item;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void didUpdateWidget(covariant AuthorDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _loadItem();
    }
  }

  void _loadItem() {
    final id = int.tryParse(widget.id);
    _item = id == null
        ? Future<Author?>.value(null)
        : context.read<AuthorListNotifier>().getById(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Автор')),
      body: FutureBuilder<Author?>(
        future: _item,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Не удалось загрузить автора.'));
          }
          final item = snapshot.data;
          if (item == null) {
            return const Center(child: Text('Автор не найден'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('ID: ${item.id}'),
              Text('Имя: ${item.firstName}'),
              Text('Фамилия: ${item.lastName}'),
              Text('Страна: ${item.country}'),
              Text('Год рождения: ${item.birthYear.toString()}'),
            ],
          );
        },
      ),
    );
  }
}
