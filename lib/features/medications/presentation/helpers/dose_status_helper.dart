import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dose_event.dart';

enum DoseDisplayStatus { programado, pendente, tomado, pulado, adiado }

class DoseStatusHelper {
  final DoseEvent event;
  DoseStatusHelper(this.event);

  bool get _isOverdue =>
      event.status == 'pendente' && event.scheduledAt.isBefore(DateTime.now());

  DoseDisplayStatus get displayStatus {
    switch (event.status) {
      case 'pendente':
        return _isOverdue
            ? DoseDisplayStatus.pendente
            : DoseDisplayStatus.programado;
      case 'tomado':
        return DoseDisplayStatus.tomado;
      case 'atrasado':
        return DoseDisplayStatus.pendente;
      case 'pulado':
        return DoseDisplayStatus.pulado;
      case 'adiado':
        return DoseDisplayStatus.adiado;
      default:
        return DoseDisplayStatus.programado;
    }
  }

  Color get color => switch (displayStatus) {
        DoseDisplayStatus.tomado => AppColors.success,
        DoseDisplayStatus.programado => AppColors.info,
        DoseDisplayStatus.pendente => AppColors.error,
        DoseDisplayStatus.pulado => AppColors.error,
        DoseDisplayStatus.adiado => AppColors.info,
      };

  String get label => switch (displayStatus) {
        DoseDisplayStatus.tomado => 'Tomado',
        DoseDisplayStatus.programado => 'Programado',
        DoseDisplayStatus.pendente => 'Pendente',
        DoseDisplayStatus.pulado => 'Pulado',
        DoseDisplayStatus.adiado => 'Adiado',
      };

  IconData get icon => switch (displayStatus) {
        DoseDisplayStatus.tomado => Icons.check_circle_outline_rounded,
        DoseDisplayStatus.programado => Icons.schedule_outlined,
        DoseDisplayStatus.pendente => Icons.notifications_active_outlined,
        DoseDisplayStatus.pulado => Icons.cancel_outlined,
        DoseDisplayStatus.adiado => Icons.snooze_outlined,
      };

  bool get isActionable =>
      displayStatus == DoseDisplayStatus.programado ||
      displayStatus == DoseDisplayStatus.pendente;

  String get countdown {
    final now = DateTime.now();

    if (displayStatus == DoseDisplayStatus.pendente) {
      final elapsed = now.difference(event.scheduledAt);
      if (elapsed.inHours > 0) {
        return 'há ${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}min';
      }
      return 'há ${elapsed.inMinutes}min';
    }

    if (displayStatus == DoseDisplayStatus.programado) {
      final diff = event.scheduledAt.difference(now);
      if (diff.inHours > 0) {
        return 'em ${diff.inHours}h ${diff.inMinutes.remainder(60)}min';
      }
      return 'em ${diff.inMinutes}min';
    }

    return '';
  }
}
