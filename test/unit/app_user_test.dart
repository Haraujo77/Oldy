import 'package:flutter_test/flutter_test.dart';
import 'package:oldy/features/auth/domain/entities/app_user.dart';

void main() {
  final now = DateTime(2025, 6, 15, 10, 30);

  AppUser makeUser({
    String uid = 'uid1',
    String email = 'maria@email.com',
    String displayName = 'Maria Silva',
    String? photoUrl = 'https://example.com/photo.jpg',
    String? phone = '+5511999999999',
    String? relation = 'Filha',
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      phone: phone,
      relation: relation,
      createdAt: createdAt ?? now,
    );
  }

  group('AppUser.fromMap / toMap roundtrip', () {
    test('full user survives roundtrip', () {
      final user = makeUser();
      final map = user.toMap();
      final restored = AppUser.fromMap(map);

      expect(restored.uid, user.uid);
      expect(restored.email, user.email);
      expect(restored.displayName, user.displayName);
      expect(restored.photoUrl, user.photoUrl);
      expect(restored.phone, user.phone);
      expect(restored.relation, user.relation);
      expect(restored.createdAt, user.createdAt);
    });

    test('null optional fields survive roundtrip', () {
      final user = makeUser(
        photoUrl: null,
        phone: null,
        relation: null,
      );
      final restored = AppUser.fromMap(user.toMap());

      expect(restored.photoUrl, isNull);
      expect(restored.phone, isNull);
      expect(restored.relation, isNull);
    });

    test('displayName defaults to empty string when missing in map', () {
      final restored = AppUser.fromMap({
        'uid': 'uid1',
        'email': 'a@b.com',
        'createdAt': now.toIso8601String(),
      });
      expect(restored.displayName, '');
    });

    test('createdAt defaults to now when missing in map', () {
      final before = DateTime.now();
      final restored = AppUser.fromMap({
        'uid': 'uid1',
        'email': 'a@b.com',
      });
      final after = DateTime.now();

      expect(restored.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(restored.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('AppUser.copyWith', () {
    test('changes only specified fields', () {
      final original = makeUser();
      final updated = original.copyWith(
        displayName: 'Ana Costa',
        phone: '+5521888888888',
      );

      expect(updated.displayName, 'Ana Costa');
      expect(updated.phone, '+5521888888888');
      expect(updated.uid, original.uid);
      expect(updated.email, original.email);
      expect(updated.photoUrl, original.photoUrl);
      expect(updated.relation, original.relation);
      expect(updated.createdAt, original.createdAt);
    });

    test('returns identical values when no arguments passed', () {
      final original = makeUser();
      final copy = original.copyWith();

      expect(copy.uid, original.uid);
      expect(copy.email, original.email);
      expect(copy.displayName, original.displayName);
      expect(copy.photoUrl, original.photoUrl);
      expect(copy.phone, original.phone);
      expect(copy.relation, original.relation);
      expect(copy.createdAt, original.createdAt);
    });
  });
}
