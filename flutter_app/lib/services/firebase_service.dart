import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sensor_reading.dart';
import 'authentication_service.dart';
import 'firestore_service.dart';
import 'storage_service.dart';

class FirebaseService {
  final AuthenticationService _authService = AuthenticationService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  // --- AUTHENTICATION ---
  User? get currentUser => _authService.currentUser;

  Future<Map<String, dynamic>> login(String email, String password) =>
      _authService.login(email, password);

  Future<Map<String, dynamic>> register(String username, String email, String password) =>
      _authService.register(username, email, password);

  Future<Map<String, dynamic>> signInWithGoogle() =>
      _authService.signInWithGoogle();

  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) =>
      _authService.sendPasswordResetEmail(email);

  Future<void> logout() => _authService.logout();

  // --- FIRESTORE SERVICES ---
  Stream<SensorReading?> streamLatestSensorReading(String userId) =>
      _firestoreService.streamLatestSensorReading(userId);

  Future<List<dynamic>> fetchHistoryLogs(String userId) async {
    // Return a one-off future snapshot for backward compatibility
    final logs = await _firestoreService.streamHistoryLogs(userId).first;
    return logs;
  }

  Stream<List<Map<String, dynamic>>> streamHistoryLogs(String userId) =>
      _firestoreService.streamHistoryLogs(userId);

  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) =>
      _firestoreService.updateUserProfile(userId, data);

  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    final snapshot = await _firestoreService.streamUserProfile(userId).first;
    return snapshot.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(String userId) =>
      _firestoreService.streamUserProfile(userId);

  // --- STORAGE SERVICES ---
  Future<String?> uploadProfilePicture(String userId, Uint8List bytes) =>
      _storageService.uploadProfilePicture(userId, bytes);

  Future<String?> uploadMedicalReport(String userId, String logId, Uint8List bytes) =>
      _storageService.uploadMedicalReport(userId, logId, bytes);

  Future<bool> deletePredictionLog(String userId, String logId) =>
      _firestoreService.deletePredictionLog(userId, logId);

  Future<bool> deleteMedicalReport(String userId, String logId) =>
      _storageService.deleteMedicalReport(userId, logId);
}