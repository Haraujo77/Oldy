import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_patient_repository.dart';
import '../../domain/entities/invite.dart';
import '../../domain/entities/patient.dart';
import '../../domain/entities/patient_member.dart';
import '../../domain/repositories/patient_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return FirebasePatientRepository();
});

final selectedPatientIdProvider = StateProvider<String?>((ref) => null);

final myPatientsProvider = StreamProvider<List<Patient>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(patientRepositoryProvider).watchMyPatients(user.uid);
});

final selectedPatientProvider = StreamProvider<Patient?>((ref) {
  final patientId = ref.watch(selectedPatientIdProvider);
  if (patientId == null) return Stream.value(null);
  final firestore = ref.watch(patientRepositoryProvider) as FirebasePatientRepository;
  return firestore.watchPatient(patientId);
});

final patientMembersProvider = StreamProvider<List<PatientMember>>((ref) {
  final patientId = ref.watch(selectedPatientIdProvider);
  if (patientId == null) return Stream.value([]);
  return ref.watch(patientRepositoryProvider).watchMembers(patientId);
});

final patientInvitesProvider = StreamProvider<List<Invite>>((ref) {
  final patientId = ref.watch(selectedPatientIdProvider);
  if (patientId == null) return Stream.value([]);
  return (ref.watch(patientRepositoryProvider) as FirebasePatientRepository)
      .watchInvites(patientId);
});

final pendingInvitesForUserProvider = StreamProvider<List<Invite>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null || user.email.isEmpty) return Stream.value([]);
  return (ref.watch(patientRepositoryProvider) as FirebasePatientRepository)
      .watchInvitesForEmail(user.email);
});
