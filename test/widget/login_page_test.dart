import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oldy/features/auth/presentation/pages/login_page.dart';

void main() {
  Widget buildTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: LoginPage(),
      ),
    );
  }

  testWidgets('displays email field', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'E-mail'), findsOneWidget);
  });

  testWidgets('displays password field', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'Senha'), findsOneWidget);
  });

  testWidgets('displays Entrar button', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('empty form validation shows errors', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail obrigatório'), findsOneWidget);
    expect(find.text('Senha obrigatória'), findsOneWidget);
  });
}
