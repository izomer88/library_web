import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../state/book_list_notifier.dart';

class BookDetailsScreen extends StatefulWidget {
  const BookDetailsScreen({super.key, required this.id});

  final String id;

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late Future<Book?> _item;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void didUpdateWidget(covariant BookDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _loadItem();
    }
  }

  void _loadItem() {
    final id = int.tryParse(widget.id);
    _item = id == null
        ? Future<Book?>.value(null)
        : context.read<BookListNotifier>().getById(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Книга')),
      body: FutureBuilder<Book?>(
        future: _item,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Не удалось загрузить книгу.'));
          }
          final item = snapshot.data;
          if (item == null) {
            return const Center(child: Text('Книга не найдена'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('ID: ${item.id}'),
              Text('Название: ${item.title}'),
              Text('ISBN: ${item.isbn}'),
              Text('Год: ${item.year.toString()}'),
              Text('Страницы: ${item.pages.toString()}'),
              Text('Всего экземпляров: ${item.copiesTotal}'),
              Text('Доступно экземпляров: ${item.copiesAvailable}'),
            ],
          );
        },
      ),
    );
  }
}
