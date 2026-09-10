import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';

import 'screens/book_form_screen.dart';
import 'screens/author_form_screen.dart';

import 'screens/author_details_screen.dart';
import 'screens/authors_screen.dart';
import 'screens/book_details_screen.dart';
import 'screens/books_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/books'),
    GoRoute(path: '/books', builder: (context, state) => const BooksScreen()),
    GoRoute(
      path: '/books/new',
      builder: (context, state) => const BookFormScreen(),
    ),
    GoRoute(
      path: '/books/:id/edit',
      builder: (context, state) => BookFormScreen(
        key: ValueKey(state.uri.path),
        id: state.pathParameters['id'],
      ),
    ),
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
      path: '/authors/new',
      builder: (context, state) => const AuthorFormScreen(),
    ),
    GoRoute(
      path: '/authors/:id/edit',
      builder: (context, state) => AuthorFormScreen(
        key: ValueKey(state.uri.path),
        id: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/authors/:id',
      builder: (context, state) =>
          AuthorDetailsScreen(id: state.pathParameters['id']!),
    ),
  ],
);
