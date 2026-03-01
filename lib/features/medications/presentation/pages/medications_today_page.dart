import 'package:flutter/material.dart';
import '../../../../core/widgets/oldy_empty_state.dart';

class MedicationsTodayPage extends StatelessWidget {
  const MedicationsTodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicamentos')),
      body: const OldyEmptyState(
        icon: Icons.medication_outlined,
        title: 'Nenhum medicamento cadastrado',
        subtitle: 'Adicione medicamentos ao plano para acompanhar as doses',
        actionLabel: 'Adicionar medicamento',
      ),
    );
  }
}
