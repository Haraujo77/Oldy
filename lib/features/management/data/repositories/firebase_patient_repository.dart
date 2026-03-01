import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/patient.dart';
import '../../domain/entities/patient_member.dart';
import '../../domain/entities/invite.dart';
import '../../domain/repositories/patient_repository.dart';

class FirebasePatientRepository implements PatientRepository {
  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();

  FirebasePatientRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _patientsCol =>
      _firestore.collection('patients');

  @override
  Stream<List<Patient>> watchMyPatients(String userId) {
    return _firestore
        .collectionGroup('members')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return <Patient>[];

      final patientIds = snapshot.docs.map((doc) {
        return doc.reference.parent.parent!.id;
      }).toSet();

      final patients = <Patient>[];
      for (final id in patientIds) {
        final doc = await _patientsCol.doc(id).get();
        if (doc.exists && doc.data() != null) {
          patients.add(Patient.fromMap(doc.data()!));
        }
      }
      return patients;
    });
  }

  @override
  Future<Patient> getPatient(String patientId) async {
    final doc = await _patientsCol.doc(patientId).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Paciente não encontrado');
    }
    return Patient.fromMap(doc.data()!);
  }

  @override
  Future<Patient> createPatient(Patient patient, String userId) async {
    final id = _uuid.v4();
    final newPatient = patient.copyWith(
      id: id,
      createdAt: DateTime.now(),
      createdBy: userId,
    );

    await _patientsCol.doc(id).set(newPatient.toMap());

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};

    final member = PatientMember(
      userId: userId,
      displayName: userData['displayName'] as String? ?? '',
      email: userData['email'] as String? ?? '',
      photoUrl: userData['photoUrl'] as String?,
      role: 'admin',
      status: 'active',
      joinedAt: DateTime.now(),
    );

    await _patientsCol
        .doc(id)
        .collection('members')
        .doc(userId)
        .set(member.toMap());

    return newPatient;
  }

  @override
  Future<void> updatePatient(Patient patient) async {
    await _patientsCol.doc(patient.id).update(patient.toMap());
  }

  @override
  Future<void> deletePatient(String patientId) async {
    await _patientsCol.doc(patientId).delete();
  }

  @override
  Stream<List<PatientMember>> watchMembers(String patientId) {
    return _patientsCol
        .doc(patientId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PatientMember.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<void> updateMemberRole(
      String patientId, String userId, String role) async {
    await _patientsCol
        .doc(patientId)
        .collection('members')
        .doc(userId)
        .update({'role': role});
  }

  @override
  Future<void> removeMember(String patientId, String userId) async {
    await _patientsCol
        .doc(patientId)
        .collection('members')
        .doc(userId)
        .delete();
  }

  @override
  Future<Invite> createInvite(
    String patientId,
    String email,
    String role,
    String createdBy,
  ) async {
    final id = _uuid.v4();
    final code = _uuid.v4().substring(0, 8).toUpperCase();

    final invite = Invite(
      id: id,
      code: code,
      patientId: patientId,
      role: role,
      email: email,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      status: 'pending',
    );

    await _patientsCol
        .doc(patientId)
        .collection('invites')
        .doc(id)
        .set(invite.toMap());

    return invite;
  }

  @override
  Future<void> acceptInvite(String inviteCode, String userId) async {
    final query = await _firestore
        .collectionGroup('invites')
        .where('code', isEqualTo: inviteCode)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Convite não encontrado ou já utilizado');
    }

    final inviteDoc = query.docs.first;
    final invite = Invite.fromMap(inviteDoc.data());

    if (invite.expiresAt.isBefore(DateTime.now())) {
      await inviteDoc.reference.update({'status': 'expired'});
      throw Exception('Convite expirado');
    }

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};

    final member = PatientMember(
      userId: userId,
      displayName: userData['displayName'] as String? ?? '',
      email: userData['email'] as String? ?? '',
      photoUrl: userData['photoUrl'] as String?,
      role: invite.role,
      status: 'active',
      joinedAt: DateTime.now(),
      invitedBy: invite.createdBy,
    );

    final batch = _firestore.batch();
    batch.set(
      _patientsCol
          .doc(invite.patientId)
          .collection('members')
          .doc(userId),
      member.toMap(),
    );
    batch.update(inviteDoc.reference, {'status': 'accepted'});
    await batch.commit();
  }

  @override
  Future<List<Invite>> getInvites(String patientId) async {
    final snapshot = await _patientsCol
        .doc(patientId)
        .collection('invites')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Invite.fromMap(doc.data()))
        .toList();
  }
}
