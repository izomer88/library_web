import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/main.dart';
import 'package:library_web/router.dart';

void main() {
  testWidgets('Корневой маршрут открывает список книг', (tester) async {
    router.go('/');
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/books');
    expect(find.text('Дом у реки'), findsOneWidget);
  });
}
