import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o Oldy')),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.favorite_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            AppSpacing.verticalLg,
            Text(
              'Oldy',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            AppSpacing.verticalXs,
            Text(
              'Versão 1.0.0',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Text(
                  'O Oldy é um aplicativo de gestão de saúde pensado para quem cuida de idosos. '
                  'Acompanhe métricas de saúde, medicamentos, atividades e muito mais, tudo em um só lugar.\n\n'
                  'Desenvolvido com carinho para facilitar o cuidado de quem você ama.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              '© 2026 Oldy App',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
