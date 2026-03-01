import 'package:flutter/material.dart';
import '../../../../core/widgets/oldy_empty_state.dart';

class HealthOverviewPage extends StatelessWidget {
  const HealthOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saúde')),
      body: const OldyEmptyState(
        icon: Icons.monitor_heart_outlined,
        title: 'Nenhuma métrica configurada',
        subtitle: 'Configure o plano de saúde para começar a monitorar',
        actionLabel: 'Configurar plano',
      ),
    );
  }
}
