import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Backend service for admin authentication using PIN-based login
/// This service handles the complete authentication flow:
/// PIN → Firestore query → retrieve credentials → Firebase Auth login
class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Authenticates an admin user using their PIN number
  /// 
  /// Flow:
  /// 1. Query Firestore users collection for matching PIN
  /// 2. Retrieve email and password from the document
  /// 3. Authenticate using Firebase Auth with email/password
  /// 4. Update lastLogin timestamp
  /// 5. Return authenticated User object
  /// 
  /// Throws:
  /// - Exception if PIN is invalid or not found
  /// - FirebaseAuthException if authentication fails
  /// - Exception for any other errors during the process
  Future<User> loginWithPin(String pin) async {
    try {
      print('🔐 [AdminAuthService] PIN received: ${pin.replaceAll(RegExp(r'.'), '*')}');
      
      // Validate PIN input
      if (pin.isEmpty) {
        throw Exception('PIN cannot be empty');
      }

      // Query Firestore for user with matching PIN
      print('🔍 [AdminAuthService] Querying Firestore for PIN match...');
      final QuerySnapshot querySnapshot = await _firestore
          .collection('admins')
          .where('pin', isEqualTo: pin)
          .limit(1)
          .get();

      print('📊 [AdminAuthService] Firestore query result: ${querySnapshot.docs.length} document(s) found');

      // Check if user with PIN exists
      if (querySnapshot.docs.isEmpty) {
        print('❌ [AdminAuthService] No user found with provided PIN');
        throw Exception('Invalid PIN. Please try again.');
      }

      // Extract user data from Firestore document
      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data() as Map<String, dynamic>;

      final String? email = userData['email'] as String?;
      final String? password = userData['password'] as String?;
      final String? role = userData['role'] as String?;
      final String? status = userData['status'] as String?;

      print('📧 [AdminAuthService] Email retrieved: ${email ?? 'null'}');
      print('👤 [AdminAuthService] Role: ${role ?? 'null'}');
      print('📍 [AdminAuthService] Status: ${status ?? 'null'}');

      // Validate required fields
      if (email == null || email.isEmpty) {
        throw Exception('User email not found in database');
      }

      if (password == null || password.isEmpty) {
        throw Exception('User password not found in database');
      }

      // Optional: Verify user is an admin
      if (role != null && role != 'admin') {
        print('⚠️ [AdminAuthService] Warning: User role is not admin: $role');
      }

      // Optional: Check if user account is active
      if (status != null && status != 'active') {
        throw Exception('User account is not active. Status: $status');
      }

      // Authenticate with Firebase Auth using email and password
      print('🔑 [AdminAuthService] Attempting Firebase Authentication...');
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ [AdminAuthService] Firebase login successful!');
      print('👤 [AdminAuthService] User ID: ${userCredential.user?.uid}');

      // Update lastLogin timestamp in Firestore
      try {
        await _firestore.collection('admins').doc(userDoc.id).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('⏰ [AdminAuthService] lastLogin timestamp updated');
      } catch (e) {
        print('⚠️ [AdminAuthService] Failed to update lastLogin: $e');
        // Don't throw - login was successful, timestamp update is optional
      }

      // Return authenticated user
      if (userCredential.user == null) {
        throw Exception('Authentication succeeded but user object is null');
      }

      return userCredential.user!;

    } on FirebaseAuthException catch (e) {
      print('❌ [AdminAuthService] Firebase Auth error: ${e.code} - ${e.message}');
      
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email');
        case 'wrong-password':
          throw Exception('Invalid credentials');
        case 'user-disabled':
          throw Exception('This account has been disabled');
        case 'invalid-email':
          throw Exception('Invalid email format');
        case 'too-many-requests':
          throw Exception('Too many failed attempts. Please try again later');
        default:
          throw Exception('Authentication failed: ${e.message}');
      }
    } catch (e) {
      print('❌ [AdminAuthService] Unexpected error: $e');
      rethrow;
    }
  }

  /// Signs out the current user
  Future<void> logout() async {
    try {
      print('🚪 [AdminAuthService] Logging out user...');
      await _auth.signOut();
      print('✅ [AdminAuthService] Logout successful');
    } catch (e) {
      print('❌ [AdminAuthService] Logout error: $e');
      rethrow;
    }
  }

  /// Gets the currently authenticated user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Fetches user data from Firestore by PIN
  Future<Map<String, dynamic>> getUserData(String pin) async {
    try {
      print('📋 [AdminAuthService] Fetching user data for PIN...');
      
      final querySnapshot = await _firestore
          .collection('admins')
          .where('pin', isEqualTo: pin)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('User data not found');
      }

      final userData = querySnapshot.docs.first.data();
      print('✅ [AdminAuthService] User data retrieved successfully');
      
      return userData;
    } catch (e) {
      print('❌ [AdminAuthService] Error fetching user data: $e');
      rethrow;
    }
  }

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
