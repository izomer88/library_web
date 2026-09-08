import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'repositories/in_memory_author_repository.dart';
import 'repositories/in_memory_book_repository.dart';
import 'router.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';

void main() {
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final repository = InMemoryBookRepository();
            return BookListNotifier(repository);
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final repository = InMemoryAuthorRepository();
            return AuthorListNotifier(repository);
          },
        ),
      ],
      child: MaterialApp.router(title: 'Библиотека', routerConfig: router),
    );
  }
}
