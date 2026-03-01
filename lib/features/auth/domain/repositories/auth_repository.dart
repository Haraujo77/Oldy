import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  Future<AppUser?> get currentUser;
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> registerWithEmail(String email, String password, String displayName);
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
  Future<void> updateProfile({String? displayName, String? photoUrl, String? phone, String? relation});
}
