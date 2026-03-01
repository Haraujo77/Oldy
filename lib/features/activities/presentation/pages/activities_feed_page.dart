import 'package:flutter/material.dart';
import '../../../../core/widgets/oldy_empty_state.dart';

class ActivitiesFeedPage extends StatelessWidget {
  const ActivitiesFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atividades')),
      body: const OldyEmptyState(
        icon: Icons.feed_outlined,
        title: 'Nenhuma atividade registrada',
        subtitle: 'Crie seu primeiro post de atividade',
        actionLabel: 'Novo post',
      ),
    );
  }
}
