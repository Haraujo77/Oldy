// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Oldy';

  @override
  String hello(String name) {
    return 'Hello, $name';
  }

  @override
  String get login => 'Sign in';

  @override
  String get register => 'Create account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get home => 'Home';

  @override
  String get health => 'Health';

  @override
  String get medications => 'Medications';

  @override
  String get activities => 'Activities';

  @override
  String get settings => 'Settings';

  @override
  String get myPatients => 'My Patients';

  @override
  String get addPatient => 'Add Patient';

  @override
  String get members => 'Members';

  @override
  String get invite => 'Invite';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get noData => 'No data';

  @override
  String get retry => 'Retry';

  @override
  String get markAsTaken => 'Mark as taken';

  @override
  String get today => 'Today';

  @override
  String get history => 'History';

  @override
  String get newRecord => 'New record';

  @override
  String get profile => 'Profile';

  @override
  String get logOut => 'Log out';

  @override
  String get syncing => 'Syncing...';

  @override
  String get offline => 'No connection';

  @override
  String get bloodPressure => 'Blood pressure';

  @override
  String get heartRate => 'Heart rate';

  @override
  String get oxygenSaturation => 'Oxygen saturation';

  @override
  String get temperature => 'Temperature';

  @override
  String get glucose => 'Glucose';

  @override
  String get weight => 'Weight';

  @override
  String get sleep => 'Sleep';

  @override
  String get steps => 'Steps';
}
