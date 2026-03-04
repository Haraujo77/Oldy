import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  ImageUploadService({
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    return _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
  }

  Future<String> uploadUserPhoto(String userId, XFile image) async {
    final ref = _storage.ref('users/$userId/profile.jpg');
    await ref.putFile(
      File(image.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<String> uploadPatientPhoto(String patientId, XFile image) async {
    final ref = _storage.ref('patients/$patientId/profile.jpg');
    await ref.putFile(
      File(image.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<String> uploadMedicationPhoto(
    String patientId,
    String medPlanId,
    XFile image,
  ) async {
    final ref = _storage.ref('patients/$patientId/medications/$medPlanId.jpg');
    await ref.putFile(
      File(image.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
