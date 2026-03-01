abstract final class AppConstants {
  static const String appName = 'Oldy';
  static const int historyPageSize = 10;
  static const int maxPhotosPerPost = 5;
  static const int maxAudioDurationSeconds = 120;
  static const int inviteExpirationDays = 7;
  static const int healthSyncIntervalHours = 24;

  static const List<String> activityCategories = [
    'Banho',
    'Alimentação',
    'Fisioterapia',
    'Visita médica',
    'Visita familiar',
    'Exercício',
    'Outro',
  ];

  static const List<String> medicationForms = [
    'Comprimido',
    'Cápsula',
    'Gotas',
    'Injeção',
    'Pomada',
    'Xarope',
    'Adesivo',
    'Inalação',
    'Outro',
  ];

  static const List<String> doseStatuses = [
    'pendente',
    'tomado',
    'atrasado',
    'pulado',
    'adiado',
  ];

  static const List<String> memberRoles = [
    'admin',
    'editor',
    'viewer',
  ];

  static const List<String> relations = [
    'Filho(a)',
    'Cônjuge',
    'Neto(a)',
    'Cuidador(a)',
    'Médico(a)',
    'Enfermeiro(a)',
    'Outro',
  ];
}
