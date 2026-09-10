import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/book_repository.dart';
import 'repositories/author_repository.dart';
import 'repositories/preferences_book_repository.dart';
import 'repositories/preferences_author_repository.dart';

import 'repositories/in_memory_author_repository.dart';
import 'repositories/in_memory_book_repository.dart';
import 'router.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final preferences = await SharedPreferences.getInstance();
  final books = await PreferencesBookRepository.open(preferences);
  final authors = await PreferencesAuthorRepository.open(preferences);
  runApp(MyApp(bookRepository: books, authorRepository: authors));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.bookRepository, this.authorRepository});

  final BookRepository? bookRepository;
  final AuthorRepository? authorRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final repository = bookRepository ?? InMemoryBookRepository();
            return BookListNotifier(repository);
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final repository = authorRepository ?? InMemoryAuthorRepository();
            return AuthorListNotifier(repository);
          },
        ),
      ],
      child: MaterialApp.router(title: 'Библиотека', routerConfig: router),
    );
  }
}
