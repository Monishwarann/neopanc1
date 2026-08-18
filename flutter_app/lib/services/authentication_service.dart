import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream Auth State (Real-Time session changes)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        // Fetch username from Firestore
        final doc = await _db.collection('users').doc(user.uid).get();
        final username = doc.data()?['username'] ?? 'User';
        
        return {
          'user_id': user.uid,
          'username': username,
          'email': user.email,
        };
      }
      return {'message': 'Login failed: Unknown error'};
    } on FirebaseAuthException catch (e) {
      return {'message': e.message ?? 'Authentication failed'};
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  // Register
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user;
      
      if (user != null) {
        // Create user document in Firestore with detailed initial profile fields
        await _db.collection('users').doc(user.uid).set({
          'username': username,
          'email': user.email,
          'phone': '',
          'age': 0,
          'gender': '',
          'bloodGroup': '',
          'height': 0.0,
          'weight': 0.0,
          'bmi': 0.0,
          'address': '',
          'profileImageBase64': '', // Backward compatibility, but we use Storage URLs
          'profileImageUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        return {
          'user_id': user.uid,
          'username': username,
          'email': user.email,
        };
      }
      return {'message': 'Registration failed: Unknown error'};
    } on FirebaseAuthException catch (e) {
      return {'message': e.message ?? 'Registration failed'};
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  // Google Sign-In
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return {'message': 'Google Sign-In canceled'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Save or update user document in Firestore
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _db.collection('users').doc(user.uid).set({
            'username': user.displayName ?? 'Google User',
            'email': user.email,
            'phone': user.phoneNumber ?? '',
            'age': 0,
            'gender': '',
            'bloodGroup': '',
            'height': 0.0,
            'weight': 0.0,
            'bmi': 0.0,
            'address': '',
            'profileImageUrl': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        
        return {
          'user_id': user.uid,
          'username': user.displayName ?? 'Google User',
          'email': user.email,
        };
      }
      return {'message': 'Google Sign-In failed: Unknown error'};
    } catch (e) {
      return {'message': 'Google Sign-In Error: $e'};
    }
  }

  // Forgot Password / Reset Link via Firebase Auth
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {'success': true, 'message': 'Password reset email sent successfully.'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Failed to send reset email.'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      print("Google Sign-In signOut error (ignored during standard signout): $e");
    }
    await _auth.signOut();
  }
}
