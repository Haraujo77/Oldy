import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oldy/app.dart';

void main() {
  testWidgets('App starts and shows splash', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: OldyApp()),
    );

    expect(find.text('Oldy'), findsOneWidget);
    expect(find.text('Cuidado que conecta'), findsOneWidget);
  });
}
