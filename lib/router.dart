import 'package:go_router/go_router.dart';

import 'screens/author_details_screen.dart';
import 'screens/authors_screen.dart';
import 'screens/book_details_screen.dart';
import 'screens/books_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/books'),
    GoRoute(path: '/books', builder: (context, state) => const BooksScreen()),
    GoRoute(
      path: '/books/:id',
      builder: (context, state) =>
          BookDetailsScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/authors',
      builder: (context, state) => const AuthorsScreen(),
    ),
    GoRoute(
      path: '/authors/:id',
      builder: (context, state) =>
          AuthorDetailsScreen(id: state.pathParameters['id']!),
    ),
  ],
);
