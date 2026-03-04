import 'dart:async';

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
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
      final data = userDoc.data();
      if (data == null) return <String>[];

      var patientIds =
          (data['patientIds'] as List<dynamic>?)?.cast<String>() ?? [];

      final repaired = data['_patientsRepaired'] as bool? ?? false;
      if (!repaired) {
        final orphanIds = await _repairOrphanedPatients(userId, data);
        final merged = {...patientIds, ...orphanIds}.toList();
        if (merged.length > patientIds.length) {
          patientIds = merged;
        }
      }
      return patientIds;
    }).transform(_SwitchMapTransformer((patientIds) {
      if (patientIds.isEmpty) return Stream.value(<Patient>[]);

      final staleIds = <String>[];

      final streams = patientIds.map((id) =>
          _patientsCol.doc(id).snapshots().map((doc) {
            if (!doc.exists || doc.data() == null) return null;
            return Patient.fromMap(doc.data()!);
          }).handleError((error) {
            staleIds.add(id);
            return null;
          }));

      return _combineLatest<Patient?>(streams.toList()).map((list) {
        if (staleIds.isNotEmpty) {
          _cleanupStalePatientIds(userId, staleIds);
        }
        return list.whereType<Patient>().toList();
      });
    }));
  }

  Future<void> _cleanupStalePatientIds(
      String userId, List<String> staleIds) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'patientIds': FieldValue.arrayRemove(staleIds),
      });
    } catch (_) {}
  }

  static Stream<List<T>> _combineLatest<T>(List<Stream<T>> streams) {
    if (streams.isEmpty) return Stream.value([]);
    if (streams.length == 1) return streams.first.map((e) => [e]);

    final controller = StreamController<List<T>>.broadcast();
    final latest = List<T?>.filled(streams.length, null);
    final received = List<bool>.filled(streams.length, false);
    final subscriptions = <StreamSubscription<T>>[];

    for (var i = 0; i < streams.length; i++) {
      final index = i;
      subscriptions.add(streams[index].listen(
        (value) {
          latest[index] = value;
          received[index] = true;
          if (received.every((r) => r)) {
            controller.add(List<T>.from(latest.cast<T>()));
          }
        },
        onError: (error) {
          received[index] = true;
          if (received.every((r) => r)) {
            controller.add(List<T>.from(
              latest.where((e) => e != null).cast<T>(),
            ));
          }
        },
      ));
    }

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  /// Finds patients created by this user that are missing from patientIds,
  /// repairs the member docs and user document.
  Future<List<String>> _repairOrphanedPatients(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final createdPatients = await _patientsCol
          .where('createdBy', isEqualTo: userId)
          .get();
      if (createdPatients.docs.isEmpty) {
        await _firestore.collection('users').doc(userId).update({
          '_patientsRepaired': true,
        });
        return [];
      }

      final ids = createdPatients.docs.map((d) => d.id).toList();

      for (final doc in createdPatients.docs) {
        final memberRef =
            _patientsCol.doc(doc.id).collection('members').doc(userId);
        final memberDoc = await memberRef.get();
        if (!memberDoc.exists) {
          final member = PatientMember(
            userId: userId,
            displayName: userData['displayName'] as String? ?? '',
            email: userData['email'] as String? ?? '',
            photoUrl: userData['photoUrl'] as String?,
            role: 'admin',
            status: 'active',
            joinedAt: DateTime.now(),
          );
          await memberRef.set(member.toMap());
        }
      }

      await _firestore.collection('users').doc(userId).update({
        'patientIds': FieldValue.arrayUnion(ids),
        '_patientsRepaired': true,
      });

      return ids;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Patient> getPatient(String patientId) async {
    final doc = await _patientsCol.doc(patientId).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Paciente não encontrado');
    }
    return Patient.fromMap(doc.data()!);
  }

  Stream<Patient?> watchPatient(String patientId) {
    return _patientsCol.doc(patientId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Patient.fromMap(doc.data()!);
    });
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

    await _firestore.collection('users').doc(userId).update({
      'patientIds': FieldValue.arrayUnion([id]),
    });

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

    try {
      await _firestore.collection('users').doc(userId).update({
        'patientIds': FieldValue.arrayRemove([patientId]),
      });
    } catch (_) {
      // The admin may not have permission to update another user's document.
      // The stale patientId will be cleaned up when that user loads their list.
    }
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
      email: email.trim().toLowerCase(),
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

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userEmail = (userDoc.data()?['email'] as String?)?.trim().toLowerCase() ?? '';
    final inviteEmail = invite.email.trim().toLowerCase();

    if (inviteEmail.isNotEmpty && userEmail != inviteEmail) {
      throw Exception('Este convite foi enviado para $inviteEmail. Faça login com esse e-mail para aceitar.');
    }

    if (invite.expiresAt.isBefore(DateTime.now())) {
      await inviteDoc.reference.update({'status': 'expired'});
      throw Exception('Convite expirado');
    }

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
    batch.update(
      _firestore.collection('users').doc(userId),
      {
        'patientIds': FieldValue.arrayUnion([invite.patientId]),
      },
    );
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

  @override
  Stream<List<Invite>> watchInvites(String patientId) {
    return _patientsCol
        .doc(patientId)
        .collection('invites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Invite.fromMap(doc.data())).toList());
  }

  @override
  Stream<List<Invite>> watchInvitesForEmail(String email) {
    return _firestore
        .collectionGroup('invites')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Invite.fromMap(doc.data()))
            .where((invite) => invite.expiresAt.isAfter(DateTime.now()))
            .toList());
  }

  @override
  Future<void> dismissInvite(String patientId, String inviteId) async {
    await _patientsCol
        .doc(patientId)
        .collection('invites')
        .doc(inviteId)
        .update({'status': 'dismissed'});
  }

  @override
  Future<void> deleteInvite(String patientId, String inviteId) async {
    await _patientsCol
        .doc(patientId)
        .collection('invites')
        .doc(inviteId)
        .delete();
  }

  Future<String?> getPatientDisplayName(String patientId) async {
    try {
      final doc = await _patientsCol.doc(patientId).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      return (data['nickname'] as String?)?.isNotEmpty == true
          ? data['nickname'] as String
          : data['fullName'] as String?;
    } catch (_) {
      return null;
    }
  }
}

class _SwitchMapTransformer<S, T> extends StreamTransformerBase<S, T> {
  final Stream<T> Function(S) _mapper;
  _SwitchMapTransformer(this._mapper);

  @override
  Stream<T> bind(Stream<S> stream) {
    final controller = StreamController<T>.broadcast();
    StreamSubscription<T>? innerSub;
    late final StreamSubscription<S> outerSub;

    outerSub = stream.listen(
      (event) {
        innerSub?.cancel();
        innerSub = _mapper(event).listen(
          controller.add,
          onError: controller.addError,
        );
      },
      onError: controller.addError,
      onDone: () {
        innerSub?.cancel();
        controller.close();
      },
    );

    controller.onCancel = () {
      innerSub?.cancel();
      outerSub.cancel();
    };

    return controller.stream;
  }
}
