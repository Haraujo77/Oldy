// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Oldy';

  @override
  String hello(String name) {
    return 'Olá, $name';
  }

  @override
  String get login => 'Entrar';

  @override
  String get register => 'Criar conta';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get forgotPassword => 'Esqueci minha senha';

  @override
  String get home => 'Início';

  @override
  String get health => 'Saúde';

  @override
  String get medications => 'Medicamentos';

  @override
  String get activities => 'Atividades';

  @override
  String get settings => 'Configurações';

  @override
  String get myPatients => 'Meus Pacientes';

  @override
  String get addPatient => 'Adicionar Paciente';

  @override
  String get members => 'Membros';

  @override
  String get invite => 'Convidar';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get edit => 'Editar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get loading => 'Carregando...';

  @override
  String get error => 'Erro';

  @override
  String get noData => 'Nenhum dado';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get markAsTaken => 'Marcar como tomado';

  @override
  String get today => 'Hoje';

  @override
  String get history => 'Histórico';

  @override
  String get newRecord => 'Novo registro';

  @override
  String get profile => 'Perfil';

  @override
  String get logOut => 'Sair';

  @override
  String get syncing => 'Sincronizando...';

  @override
  String get offline => 'Sem conexão';

  @override
  String get bloodPressure => 'Pressão arterial';

  @override
  String get heartRate => 'Frequência cardíaca';

  @override
  String get oxygenSaturation => 'Saturação de oxigênio';

  @override
  String get temperature => 'Temperatura';

  @override
  String get glucose => 'Glicose';

  @override
  String get weight => 'Peso';

  @override
  String get sleep => 'Sono';

  @override
  String get steps => 'Passos';
}
