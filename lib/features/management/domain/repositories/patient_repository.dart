import '../entities/patient.dart';
import '../entities/patient_member.dart';
import '../entities/invite.dart';

abstract class PatientRepository {
  Stream<List<Patient>> watchMyPatients(String userId);
  Future<Patient> getPatient(String patientId);
  Future<Patient> createPatient(Patient patient, String userId);
  Future<void> updatePatient(Patient patient);
  Future<void> deletePatient(String patientId);
  Stream<List<PatientMember>> watchMembers(String patientId);
  Future<void> updateMemberRole(
      String patientId, String userId, String role);
  Future<void> removeMember(String patientId, String userId);
  Future<Invite> createInvite(
      String patientId, String email, String role, String createdBy);
  Future<void> acceptInvite(String inviteCode, String userId);
  Future<List<Invite>> getInvites(String patientId);
}
