import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload Profile Picture
  Future<String?> uploadProfilePicture(String userId, Uint8List bytes) async {
    try {
      final ref = _storage.ref().child('users/$userId/profile_pic.jpg');
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId},
      );

      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture to Firebase Storage: $e');
      return null;
    }
  }

  // Upload PDF Medical Report
  Future<String?> uploadMedicalReport(String userId, String logId, Uint8List bytes) async {
    try {
      final ref = _storage.ref().child('users/$userId/reports/$logId.pdf');
      
      final metadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'userId': userId,
          'logId': logId,
        },
      );

      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading PDF report to Firebase Storage: $e');
      return null;
    }
  }

  // Delete PDF Medical Report
  Future<bool> deleteMedicalReport(String userId, String logId) async {
    try {
      final ref = _storage.ref().child('users/$userId/reports/$logId.pdf');
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting PDF report from Firebase Storage: $e');
      return false;
    }
  }
}
