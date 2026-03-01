import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oldy/features/auth/presentation/pages/splash_page.dart';

void main() {
  testWidgets('App starts and shows splash', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SplashPage()),
        GoRoute(path: '/login', builder: (_, _) => const Scaffold()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Oldy'), findsOneWidget);
    expect(find.text('Cuidado que conecta'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
